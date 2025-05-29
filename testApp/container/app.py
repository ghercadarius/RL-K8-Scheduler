import os
from datetime import datetime
import sys
import psutil
import multiprocessing

import requests
from flask import Flask, request, jsonify


app = Flask(__name__)
print("Server started")
totalRequests = 0

@app.route('/test', methods=['GET'])
def test():
    global totalRequests
    totalRequests += 1
    return jsonify({"message": "Test app is running", "total_requests": totalRequests}), 200


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
