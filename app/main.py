from flask import Flask, jsonify, request

app = Flask(__name__)

def health_check():
    return {"status": "healthy"}

@app.route('/api/health', methods=['GET'])
def get_health():
    return jsonify(health_check()), 200

@app.route('/api/endpoint', methods=['GET'])
def get_endpoint():
    return jsonify({"expected_key": "value", "status": "success"}), 200

@app.route('/api/endpoint', methods=['POST'])
def post_endpoint():
    data = request.get_json()
    return jsonify({"expected_key": "received", "received_data": data}), 201

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000, debug=False)