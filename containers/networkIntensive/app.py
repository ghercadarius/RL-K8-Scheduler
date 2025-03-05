import os
import sys
import threading
import time

from flask import Flask, request, jsonify, Response

app = Flask(__name__)
print("Server started")
network_speed_mpbs = 10
mb_size = 1024 * 1024

def generate_data():
    data_chunk = 1024 * 10 # 10kb
    chunk_per_sec = network_speed_mpbs * mb_size // data_chunk
    while True:
        start_t = time.time()
        for _ in range(chunk_per_sec):
            yield os.urandom(data_chunk)
        cur_t = time.time() - start_t
        if cur_t < 1.0:
            time.sleep(1.0 - cur_t)

@app.route('/stream')
def stream():
    global network_speed_mpbs
    network_speed_mpbs = int(request.json.get('network_speed_mbps', 10))
    return Response(generate_data(), mimetype="application/octet-stream")

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5003)
