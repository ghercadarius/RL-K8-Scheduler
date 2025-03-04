import os
from datetime import datetime
import sys
import psutil
import multiprocessing

import requests
from flask import Flask, request, jsonify

num_cores = multiprocessing.cpu_count()

app = Flask(__name__)
print("Server started")
appWriteUrl = os.getenv('APP_WRITE_URL')
totalFibonacciCalls = 1

def fibonacci(n):
    global totalFibonacciCalls
    totalFibonacciCalls += 1
    if totalFibonacciCalls % 50000 == 0:
        print(f"Total Fibonacci calls: {totalFibonacciCalls}")
    if n <= 1:
        return n
    else:
        return fibonacci(n - 1) + fibonacci(n - 2)

@app.route('/compute', methods=['POST'])
def compute():
    data = request.json
    n = int(data.get('input', 10))
    blocked_cores_fact = int(data.get('blocked_factor', 50)) / 100
    print("Blocking cores factor {} and nr of cores is {}".format(blocked_cores_fact, int(num_cores * blocked_cores_fact)), file=sys.stderr)
    allowed_cores = list(range(int(num_cores * blocked_cores_fact)))
    psutil.Process().cpu_affinity(allowed_cores)
    result = fibonacci(n)
    return jsonify({"result": result})

@app.route('/computeAndSave', methods=['POST'])
def computeAndSave():
    data = request.json
    n = int(data.get('input', 10))
    result = fibonacci(n)
    requestJson = {
        "input": n,
        "output": result,
        "date": datetime.now().isoformat()
    }
    requestResponse = requests.post(appWriteUrl, json=requestJson)
    return jsonify({"result": result, "saved": requestResponse.text})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
