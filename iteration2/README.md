# Iteration2 SKU Test Suite

Linux-first benchmark suite for running Minikube single-node SKU experiments,
deploying a Python web app, generating load, and collecting power data.

## What this suite does

1. Initializes shared infrastructure once (Minikube profile, namespace, tunnel).
2. Runs one SKU test at a time (sequential):
   - recreates cluster with SKU CPU/RAM,
   - deploys app,
   - computes safe replica count from allocatable resources,
   - runs load test and power sampler in parallel for 5 minutes.
3. Optionally runs all SKUs with continue-on-error orchestration and matrix summary.

## Prerequisites

- Linux host with KVM support.
- `minikube` with `kvm2` driver.
- `kubectl`.
- `perf` with RAPL support (`power/energy-pkg/`).
- `docker` or `podman`.
- `awk`, `sed`, `grep`, `bc`, `curl`.
- Passwordless sudo for power sampling (`sudo -n perf ...`).

Optional once after clone:

```bash
chmod +x scripts/*.sh
```

## Key files

- Config:
  - `config/common.env`
  - `config/skus.csv`
- Main scripts:
  - `scripts/startup_suite.sh`
  - `scripts/run_sku_test.sh`
  - `scripts/run_selected_skus.sh`
  - `scripts/stop_suite.sh`

## Execution model

Two-phase workflow:

1. Startup phase (run once)
2. SKU execution phase (run for each selected SKU)

`run_sku_test.sh` and `run_selected_skus.sh` require startup to be completed first.

## How to run

Run from `iteration2/`.

### 1) Startup phase (once)

```bash
bash scripts/startup_suite.sh
```

This creates common state, starts base Minikube profile, ensures namespace,
and starts/validates tunnel.

### 2) Run one SKU

```bash
bash scripts/run_sku_test.sh c1-r2g
```

Example SKU IDs are in `config/skus.csv`.

### 3) Run multiple or all SKUs

Run all:

```bash
bash scripts/run_selected_skus.sh all
```

Run selected list:

```bash
bash scripts/run_selected_skus.sh c1-r2g,c2-r4g,c4-r8g
```

### 4) Stop suite

Stop tunnel and keep cluster:

```bash
bash scripts/stop_suite.sh
```

Stop tunnel and delete cluster:

```bash
bash scripts/stop_suite.sh --delete-cluster
```

## Continue-on-error matrix controls

`run_selected_skus.sh` supports:

- `--continue-on-error` (default)
- `--stop-on-error`
- `--max-failures N`
- `--resume-from <sku_id>`

Examples:

```bash
bash scripts/run_selected_skus.sh all --continue-on-error --max-failures 3
bash scripts/run_selected_skus.sh all --stop-on-error
bash scripts/run_selected_skus.sh all --resume-from c4-r8g
```

## Power metrics details

- Sample cadence from `config/common.env`:
  - `TEST_DURATION_SECONDS` (default `300`)
  - `POWER_SAMPLE_INTERVAL_SECONDS` (default `10`)
- Output in `power_samples.csv` includes:
  - host package joules/watts from RAPL,
  - VM-attributed watts using VM CPU-time share,
  - VM PID.

Show latest sample for one run:

```bash
bash scripts/show_latest_power.sh results/<sku_id>/<run_timestamp>
```

## JMeter load testing behavior

- Load generation now uses `jmeter` in non-GUI mode via `scripts/run_load_test.sh`.
- The plan file is `jmeter/test-plan.jmx` and uses a random endpoint mix:
  - `GET /work` with randomized `mode` (`cpu`, `memory`, `io`, `mixed`) and intensity.
  - `POST /batch` with mixed tasks and randomized intensities.
- Results produced per run:
  - `jmeter_results.csv`
  - `jmeter.log`
  - `load_requests.csv` (normalized from JMeter output)
  - `load_summary.csv`

Tune load profile in `config/common.env`:

- `JMETER_THREADS`
- `JMETER_RAMP_UP_SECONDS`
- `JMETER_WORK_MIN_INTENSITY`
- `JMETER_WORK_MAX_INTENSITY`
- `JMETER_BATCH_MIN_INTENSITY`
- `JMETER_BATCH_MAX_INTENSITY`

## Results structure

- Per SKU run:
  - `results/<sku_id>/<run_timestamp>/`
  - contains rendered manifests, endpoint, load CSVs, power CSV, run summary.
- Matrix run:
  - `results/matrix-<timestamp>/`
  - `ledger.csv`
  - `summary_success.csv`
  - `summary_failed.csv`

## Plotting and insights

Use the Python analysis script to aggregate all `run_summary.csv` files,
generate graphs, and write an insights report.

Install dependencies:

```bash
pip install pandas matplotlib
```

Run analysis from `iteration2/`:

```bash
python3 scripts/plot_results.py --results-dir results --use-latest-per-sku
```

Output is written to:

- `results/analysis-<timestamp>/cleaned_runs.csv`
- `results/analysis-<timestamp>/insights.txt`
- `results/analysis-<timestamp>/throughput_by_sku.png`
- `results/analysis-<timestamp>/latency_by_sku.png`
- `results/analysis-<timestamp>/power_by_sku.png`
- `results/analysis-<timestamp>/throughput_vs_vm_watts.png`
- `results/analysis-<timestamp>/throughput_heatmap_cpu_memory.png`

## Troubleshooting

- Startup guard error (`Run startup_suite.sh first`):
  run `bash scripts/startup_suite.sh` and retry.
- Tunnel issues:
  inspect `logs/minikube_tunnel.log`.
- Power sampling fails:
  verify `sudo -n true` works and `perf` can read `power/energy-pkg/`.
- Cluster recreate is slow:
  expected for per-SKU isolation; runs are sequential by design.
