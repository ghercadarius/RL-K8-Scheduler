import os
import sys
import threading
import threading
import time
from turtledemo.chaos import jumpto

from flask import Flask, request, jsonify

app = Flask(__name__)
print("Server started")
write_speed_mbps = 10
read_speed_mbps = 10
data_file = "/data/datafile.txt"
mb_size = 1024 * 1024

os.makedirs("/data", exist_ok=True)

def write_sample_data(size_mb):
    with open(data_file, "wb") as f:
        f.write(os.urandom(size_mb * 1024 * 1024))

def read_thread():
    with open(data_file, "rb") as f:
        start_t = time.time()
        while True:
            data = f.read(mb_size)
            print(f"!! reading {data[0:3]} !!", file=sys.stderr)
            if not data:
                f.seek(0)
            cur_t = time.time() - start_t
            sleep_t = max(0, (mb_size / (read_speed_mbps * mb_size)) - cur_t)
            time.sleep(sleep_t)

def write_thread():
    with open('/data/writefile.txt', "wb") as f:
        start_t = time.time()
        while True:
            f.write(os.urandom(mb_size * 100))
            print("!! writing !!", file=sys.stderr)
            cur_t = time.time() - start_t
            sleep_t = max(0, (mb_size / (write_speed_mbps * mb_size)) - cur_t)
            time.sleep(sleep_t)
            cur_t = time.time() - start_t
            f.truncate(0)
            f.seek(0)
            sleep_t = max(0, (mb_size / (write_speed_mbps * mb_size)) - cur_t)
            time.sleep(sleep_t)

# write function to write garbage data to read, also make file

@app.route('/read', methods=['POST'])
def read():
    # read data based on read speed and mb size for ammount of time from garbage data
    global read_speed_mbps
    read_speed_mbps = int(request.json.get('read_speed_mbps', 10))
    read_call = threading.Thread(target = read_thread, daemon=True)
    read_call.start()
    return jsonify({"status": "reading"})
@app.route('/write', methods=['POST'])
def write():
    # write garbage data anywhere same as read with time
    global write_speed_mbps
    write_speed_mbps = int(request.json.get('write_speed_mbps', 10))
    write_call = threading.Thread(target=write_thread, daemon=True)
    write_call.start()
    return jsonify({"status": "writing"})
@app.route('/readwrite', methods=['POST'])
def readwrite():
    # read from data and write in two different threads
    global read_speed_mbps, write_speed_mbps
    read_speed_mbps = int(request.json.get('read_speed_mbps', 10))
    write_speed_mbps = int(request.json.get('write_speed_mbps', 10))

    read_call = threading.Thread(target=read_thread, daemon=True)
    write_call = threading.Thread(target=write_thread, daemon=True)

    read_call.start()
    write_call.start()
    return jsonify({"status": "reading and writing"})

if __name__ == '__main__':
    write_sample_data(size_mb=100)
    app.run(host='0.0.0.0', port=5002)
    # setup for readwrite threads
