import random
from flask import Flask, request, jsonify

app = Flask(__name__)
print("Server started")
dataset = []

@app.route('/load', methods=['POST'])
def load():
    global dataset
    size_mb = int(request.json.get('size_mb', 100))
    mb_factor = 1024 * 1024 // 8
    dataset = [random.random() for _ in range(size_mb * mb_factor)]
    return jsonify({"status": "loaded", "size_mb": size_mb})

@app.route('/data', methods=['GET'])
def get_data():
    return jsonify({"data": dataset[:10]})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
