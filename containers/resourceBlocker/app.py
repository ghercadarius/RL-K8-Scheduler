import os
from datetime import datetime
import sys
import psutil
import multiprocessing
import threading
import time
import random
from flasgger import Swagger


import requests
from flask import Flask, request, jsonify, Response

class CPU:
    def __init__(self):
        self.num_cores = multiprocessing.cpu_count()
    def fibonacci(self, n):
        if n <= 1:
            return n
        else:
            return self.fibonacci(n - 1) + self.fibonacci(n - 2)

class DISK:
    def __init__(self):
        self.write_speed_mbps = 10
        self.read_speed_mbps = 10
        self.data_file = "/tmp/datafile.txt"
        self.mb_size = 1024 * 1024
        os.makedirs("/tmp", exist_ok=True)

    def write_sample_data(self, size_mb):
        with open(self.data_file, "wb") as f:
            f.write(os.urandom(size_mb * 1024 * 1024))

    def read_thread(self):
        with open(self.data_file, "rb") as f:
            start_t = time.time()
            while True:
                data = f.read(self.mb_size)
                if not data:
                    f.seek(0)
                cur_t = time.time() - start_t
                sleep_t = max(0, int((self.mb_size / (self.read_speed_mbps * self.mb_size)) - cur_t))
                time.sleep(sleep_t)

    def write_thread(self):
        with open('/tmp/writefile.txt', "wb") as f:
            start_t = time.time()
            while True:
                f.write(os.urandom(self.mb_size * 100))
                cur_t = time.time() - start_t
                sleep_t = max(0, int((self.mb_size / (self.write_speed_mbps * self.mb_size)) - cur_t))
                time.sleep(sleep_t)
                cur_t = time.time() - start_t
                f.truncate(0)
                f.seek(0)
                sleep_t = max(0, int((self.mb_size / (self.write_speed_mbps * self.mb_size)) - cur_t))
                time.sleep(sleep_t)

import socket

class NETWORK:
    def __init__(self):
        self.network_speed_mpbs = 10
        self.mb_size = 1024 * 1024

    def generate_data(self):
        data_chunk = 1024 * 10  # 10kb
        chunk_per_sec = self.network_speed_mpbs * self.mb_size // data_chunk
        while True:
            start_t = time.time()
            for _ in range(chunk_per_sec):
                yield os.urandom(data_chunk)
            cur_t = time.time() - start_t
            if cur_t < 1.0:
                time.sleep(1.0 - cur_t)

class MEMORY:
    def __init__(self):
        self.dataset = []



app = Flask(__name__)
Swagger(app)
print("Server started")

cpuBlocker = CPU()
diskBlocker = DISK()
networkBlocker = NETWORK()
memoryBlocker = MEMORY()

@app.route('/cpu', methods=['POST'])
def compute():
    """
    Compute Fibonacci
    ---
    tags:
      - CPU
    parameters:
      - in: body
        name: body
        required: true
        schema:
          type: object
          required:
            - input
          properties:
            input:
              type: integer
              description: The Fibonacci number to compute
              example: 10
            blocked_factor:
              type: integer
              description: Percentage of CPU cores to block (default is 50)
              example: 50
    responses:
      200:
        description: Fibonacci computation result
        schema:
          type: object
          properties:
            result:
              type: integer
    """
    data = request.json
    n = int(data.get('input', 10))
    blocked_cores_fact = int(data.get('blocked_factor', 50)) / 100
    allowed_cores = list(range(int(cpuBlocker.num_cores * blocked_cores_fact)))

    def cpu_task():
        psutil.Process().cpu_affinity(allowed_cores)
        cpuBlocker.fibonacci(n)

    threading.Thread(target=cpu_task, daemon=True).start()
    return jsonify({"status": "started"}), 200

@app.route('/read', methods=['POST'])
def read():
    """
    Read data from the disk
    ---
    tags:
      - DISK
    parameters:
      - in: body
        name: body
        required: true
        schema:
          type: object
          required:
            - read_speed_mbps
          properties:
            read_speed_mbps:
              type: integer
              description: Read speed in Mbps
              example: 10
    responses:
      200:
        description: Reading initiated
        schema:
          type: object
          properties:
            status:
              type: string
              example: reading
    """
    diskBlocker.read_speed_mbps = int(request.json.get('read_speed_mbps', 10))
    threading.Thread(target=diskBlocker.read_thread, daemon=True).start()
    return jsonify({"status": "reading"}), 200

@app.route('/write', methods=['POST'])
def write():
    """
    Write data to the disk
    ---
    tags:
      - DISK
    parameters:
      - in: body
        name: body
        required: true
        schema:
          type: object
          required:
            - write_speed_mbps
          properties:
            write_speed_mbps:
              type: integer
              description: Write speed in Mbps
              example: 10
    responses:
      200:
        description: Writing initiated
        schema:
          type: object
          properties:
            status:
              type: string
              example: writing
    """
    diskBlocker.write_speed_mbps = int(request.json.get('write_speed_mbps', 10))
    threading.Thread(target=diskBlocker.write_thread, daemon=True).start()
    return jsonify({"status": "writing"}), 200

@app.route('/readwrite', methods=['POST'])
def readwrite():
    """
    Concurrently read and write data on the disk
    ---
    tags:
      - DISK
    parameters:
      - in: body
        name: body
        required: true
        schema:
          type: object
          required:
            - read_speed_mbps
            - write_speed_mbps
          properties:
            read_speed_mbps:
              type: integer
              description: Read speed in Mbps
              example: 10
            write_speed_mbps:
              type: integer
              description: Write speed in Mbps
              example: 10
    responses:
      200:
        description: Concurrent read and write initiated
        schema:
          type: object
          properties:
            status:
              type: string
              example: reading and writing
    """
    diskBlocker.read_speed_mbps = int(request.json.get('read_speed_mbps', 10))
    diskBlocker.write_speed_mbps = int(request.json.get('write_speed_mbps', 10))
    threading.Thread(target=diskBlocker.read_thread, daemon=True).start()
    threading.Thread(target=diskBlocker.write_thread, daemon=True).start()
    return jsonify({"status": "reading and writing"}), 200

@app.route('/stream')
def stream():
    """
    Stream generated network data
    ---
    tags:
      - NETWORK
    parameters:
      - name: network_speed_mbps
        in: query
        type: integer
        required: false
        description: Network speed in Mbps (default is 10)
        default: 10
    responses:
      200:
        description: Stream of generated data
        content:
          application/octet-stream:
            schema:
              type: string
              format: binary
    """
    networkBlocker.network_speed_mpbs = int(request.args.get('network_speed_mbps', 10))
    return Response(networkBlocker.generate_data(), mimetype="application/octet-stream")
@app.route('/load', methods=['POST'])
def load():
    """
    Load a dataset into memory
    ---
    tags:
      - MEMORY
    parameters:
      - in: body
        name: body
        required: true
        schema:
          type: object
          required:
            - size_mb
          properties:
            size_mb:
              type: integer
              description: Size of the dataset in megabytes
              example: 100
    responses:
      200:
        description: Data loaded successfully
        schema:
          type: object
          properties:
            status:
              type: string
              example: loaded
            size_mb:
              type: integer
              example: 100
    """
    size_mb = int(request.json.get('size_mb', 100))

    def load_task():
        mb_factor = 1024 * 1024 // 40
        memoryBlocker.dataset = [random.random() for _ in range(size_mb * mb_factor)]

    threading.Thread(target=load_task, daemon=True).start()
    return jsonify({"status": "loading", "size_mb": size_mb}), 200

@app.route('/data', methods=['GET'])
def get_data():
    """
    Retrieve a portion of the loaded dataset
    ---
    tags:
      - MEMORY
    responses:
      200:
        description: Returns the first 10 items of the dataset
        schema:
          type: object
          properties:
            data:
              type: array
              items:
                type: number
              example: [0.123, 0.456, 0.789, 0.101, 0.112, 0.131, 0.415, 0.161, 0.718, 0.192]
    """
    return jsonify({"data": memoryBlocker.dataset[:10]})

@app.route('/healthz')
def healthz():
    return 'OK', 200