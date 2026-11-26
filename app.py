
from flask import Flask, request, jsonify

app = Flask(__name__)


@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "healthy"})


@app.route("/chat", methods=["POST"])
def chat():
    data = request.get_json(silent=True) or {}
    message = data.get("message", "")

    if not isinstance(message, str) or not message.strip():
        return jsonify({"error": "Valid message required"}), 400

    text = message.lower()

    blocked_patterns = [
        "ignore previous",
        "ignore all",
        "system prompt",
        "reveal instructions",
        "act as admin",
        "administrator",
        "password",
        "credit card",
        "customer pii",
        "base64",
        "decode",
        "override",
        "secret",
        "confidential",
        "jailbreak"
    ]

    if any(pattern in text for pattern in blocked_patterns):
        return jsonify({
            "reply": "I cannot comply with unauthorized requests.",
            "blocked": True
        })

    if "refund" in text:
        reply = "Refund requests are reviewed within 5 business days."
    elif "order" in text:
        reply = "Please provide your order ID."
    elif "delivery" in text:
        reply = "Standard delivery takes 3 to 5 business days."
    elif "hello" in text or "hi" in text:
        reply = "Hello! How can I help you?"
    else:
        reply = "Please contact customer support for assistance."

    return jsonify({
        "reply": reply,
        "blocked": False
    })


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5001)
