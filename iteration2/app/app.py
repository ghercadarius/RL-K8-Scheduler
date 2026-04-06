from flask import Flask, jsonify

app = Flask(__name__)


@app.get("/")
def index():
    return jsonify({"status": "ok"})


@app.get("/work")
def work():
    data = sum(i * i for i in range(20000))
    return jsonify({"result": data})


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
