
docker rm -f prometheus-gke -v 2>$null

# Step 5: Run Prometheus in Docker
docker run -d --name prometheus-gke `
    -p 9090:9090 `
    -v "$PWD/prometheus.yml:/etc/prometheus/prometheus.yml" `
    prom/prometheus

Write-Host "prometheus is now running at http://localhost:9090"
