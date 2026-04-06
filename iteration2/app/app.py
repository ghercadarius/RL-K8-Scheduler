import hashlib
import os
import tempfile
import threading
import time
from collections import deque

import psutil
from flask import Flask, jsonify, request

app = Flask(__name__)

MAX_HISTORY = 200
history_lock = threading.Lock()
work_history = deque(maxlen=MAX_HISTORY)


def clamp(value: int, low: int, high: int) -> int:
    return max(low, min(high, value))


def cpu_work(intensity: int) -> dict:
    loops = 8000 * intensity
    acc = 0
    for i in range(1, loops):
        acc = (acc + (i * i) % 9973) % 1_000_000_007
    digest = hashlib.sha256(str(acc).encode("utf-8")).hexdigest()[:16]
    return {"type": "cpu", "loops": loops, "digest": digest}


def memory_work(intensity: int) -> dict:
    chunk_mb = clamp(intensity * 6, 6, 96)
    payload = bytearray(chunk_mb * 1024 * 1024)
    step = 4096
    checksum = 0
    for i in range(0, len(payload), step):
        payload[i] = (i // step) % 256
        checksum ^= payload[i]
    digest = hashlib.md5(payload[: min(len(payload), 4_000_000)]).hexdigest()[:16]
    return {"type": "memory", "allocated_mb": chunk_mb, "checksum": checksum, "digest": digest}


def io_work(intensity: int) -> dict:
    size_mb = clamp(intensity * 3, 3, 48)
    data = os.urandom(size_mb * 1024 * 1024)
    start = time.perf_counter()
    with tempfile.NamedTemporaryFile(prefix="sku-bench-", suffix=".bin", delete=False) as tmp:
        tmp.write(data)
        path = tmp.name

    with open(path, "rb") as fp:
        read_back = fp.read()
    os.remove(path)
    elapsed_ms = (time.perf_counter() - start) * 1000
    digest = hashlib.sha1(read_back).hexdigest()[:16]
    return {"type": "io", "size_mb": size_mb, "elapsed_ms": round(elapsed_ms, 2), "digest": digest}


def mixed_work(intensity: int) -> dict:
    return {
        "type": "mixed",
        "cpu": cpu_work(max(1, intensity // 2)),
        "memory": memory_work(max(1, intensity // 2)),
        "io": io_work(max(1, intensity // 3)),
    }


def execute_mode(mode: str, intensity: int) -> dict:
    if mode == "cpu":
        return cpu_work(intensity)
    if mode == "memory":
        return memory_work(intensity)
    if mode == "io":
        return io_work(intensity)
    return mixed_work(intensity)


def record_history(entry: dict) -> None:
    with history_lock:
        work_history.append(entry)


@app.get("/")
def index():
    return jsonify(
        {
            "status": "ok",
            "service": "sku-bench-app",
            "endpoints": [
                "GET /health",
                "GET /work?mode=mixed&intensity=5",
                "POST /batch",
                "GET /history",
                "GET /metrics/self",
            ],
        }
    )


@app.get("/health")
def health():
    return jsonify({"status": "healthy", "timestamp": time.time()})


@app.get("/work")
def work():
    mode = request.args.get("mode", "mixed").strip().lower()
    if mode not in {"cpu", "memory", "io", "mixed"}:
        return jsonify({"error": "invalid mode", "allowed": ["cpu", "memory", "io", "mixed"]}), 400

    try:
        intensity = int(request.args.get("intensity", "5"))
    except ValueError:
        return jsonify({"error": "intensity must be an integer"}), 400

    intensity = clamp(intensity, 1, 20)
    started = time.perf_counter()
    result = execute_mode(mode, intensity)
    duration_ms = (time.perf_counter() - started) * 1000

    response = {
        "mode": mode,
        "intensity": intensity,
        "duration_ms": round(duration_ms, 2),
        "result": result,
    }
    record_history({"ts": time.time(), **response})
    return jsonify(response)


@app.post("/batch")
def batch():
    payload = request.get_json(silent=True) or {}
    tasks = payload.get("tasks", [])
    if not isinstance(tasks, list) or not tasks:
        return jsonify({"error": "tasks must be a non-empty list"}), 400

    if len(tasks) > 25:
        return jsonify({"error": "maximum 25 tasks allowed"}), 400

    outputs = []
    start = time.perf_counter()
    for item in tasks:
        mode = str(item.get("mode", "mixed")).lower()
        intensity = clamp(int(item.get("intensity", 3)), 1, 20)
        if mode not in {"cpu", "memory", "io", "mixed"}:
            return jsonify({"error": f"invalid mode in task: {mode}"}), 400
        outputs.append({"mode": mode, "intensity": intensity, "result": execute_mode(mode, intensity)})

    duration_ms = (time.perf_counter() - start) * 1000
    response = {"count": len(outputs), "duration_ms": round(duration_ms, 2), "outputs": outputs}
    record_history({"ts": time.time(), "mode": "batch", "intensity": len(outputs), "duration_ms": round(duration_ms, 2)})
    return jsonify(response)


@app.get("/history")
def history():
    limit = clamp(int(request.args.get("limit", 20)), 1, MAX_HISTORY)
    with history_lock:
        items = list(work_history)[-limit:]
    return jsonify({"items": items, "count": len(items)})


@app.get("/metrics/self")
def self_metrics():
    proc = psutil.Process(os.getpid())
    rss_mb = proc.memory_info().rss / (1024 * 1024)
    cpu_percent = proc.cpu_percent(interval=0.05)
    thread_count = proc.num_threads()

    return jsonify(
        {
            "pid": os.getpid(),
            "cpu_percent": cpu_percent,
            "rss_mb": round(rss_mb, 2),
            "threads": thread_count,
            "history_size": len(work_history),
        }
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
