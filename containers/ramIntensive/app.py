import random
import sys
from flask import Flask, request, jsonify

app = Flask(__name__)
print("Server started")
dataset = []

@app.route('/load', methods=['POST'])
def load():
    global dataset
    size_mb = int(request.json.get('size_mb', 100))
    print("Loading data of size {} MB".format(size_mb), file=sys.stderr)
    mb_factor = 1024 * 1024 // 40
    dataset = [random.random() for _ in range(size_mb * mb_factor)]
    return jsonify({"status": "loaded", "size_mb": size_mb})

@app.route('/data', methods=['GET'])
def get_data():
    return jsonify({"data": dataset[:10]})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
