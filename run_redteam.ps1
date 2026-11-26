
$ErrorActionPreference = "Stop"

Set-Location $PSScriptRoot

New-Item -ItemType Directory -Force -Path reports | Out-Null

Write-Host "=========================================="
Write-Host "DAY 17 - AUTOMATED SECURITY EVALUATION"
Write-Host "=========================================="

$python = Join-Path $PSScriptRoot ".venv\Scripts\python.exe"

if (-not (Test-Path $python)) {
    throw "Virtual environment Python not found."
}

$server = Start-Process `
    -FilePath $python `
    -ArgumentList "-u", "app.py" `
    -WorkingDirectory $PSScriptRoot `
    -RedirectStandardOutput "reports\flask-output.log" `
    -RedirectStandardError "reports\flask-error.log" `
    -PassThru

try {
    Write-Host "Waiting for Flask API..."

    $ready = $false

    for ($i = 0; $i -lt 15; $i++) {
        try {
            $health = Invoke-RestMethod `
                -Uri "http://127.0.0.1:5001/health" `
                -TimeoutSec 2

            if ($health.status -eq "healthy") {
                $ready = $true
                break
            }
        }
        catch {
            Start-Sleep -Seconds 2
        }
    }

    if (-not $ready) {
        Get-Content "reports\flask-error.log"
        throw "Flask API is not reachable."
    }

    Write-Host "API HEALTH CHECK: PASS" -ForegroundColor Green

    Write-Host "Testing chatbot endpoint..."

    $response = Invoke-RestMethod `
        -Uri "http://127.0.0.1:5001/chat" `
        -Method POST `
        -ContentType "application/json" `
        -Body '{"message":"Where is my order?"}'

    $response | ConvertTo-Json

    Write-Host "Starting Promptfoo security evaluation..."

    $env:NO_PROXY = "localhost,127.0.0.1"

    npx.cmd promptfoo@0.126.0 eval `
        -c redteam.yaml `
        --no-cache `
        -j 1 `
        -o reports/redteam_results.json

    $evalExit = $LASTEXITCODE

    Write-Host "Promptfoo exit code: $evalExit"

    if (Test-Path "reports\redteam_results.json") {
        Write-Host "Results file available."
    }

    Write-Host "Flask server logs:"
    Get-Content "reports\flask-error.log" -Tail 15
}
finally {
    if (-not $server.HasExited) {
        Stop-Process -Id $server.Id -Force
    }

    Write-Host "Flask process cleanup completed."
}
