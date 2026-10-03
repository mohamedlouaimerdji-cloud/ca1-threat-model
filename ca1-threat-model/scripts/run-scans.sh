#!/usr/bin/env bash
# Run ONLY against your own local Juice Shop container. Never against anything you don't own.
set -euo pipefail
mkdir -p evidence/scans

echo "[1/3] Image vulnerability scan (Trivy)"
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest \
  image --severity HIGH,CRITICAL bkimminich/juice-shop:latest | tee evidence/scans/trivy-image.txt

echo "[2/3] CIS Docker Benchmark (docker-bench-security)"
docker run --rm --net host --pid host --userns host --cap-add audit_control \
  -v /var/lib:/var/lib:ro -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v /etc:/etc:ro --label docker_bench_security \
  docker/docker-bench-security | tee evidence/scans/docker-bench.txt

echo "[3/3] OWASP ZAP baseline scan (passive) against http://localhost:3000"
docker run --rm --add-host=host.docker.internal:host-gateway \
  -v "$(pwd)/evidence/scans:/zap/wrk:rw" ghcr.io/zaproxy/zaproxy:stable \
  zap-baseline.py -t http://host.docker.internal:3000 -r zap-baseline.html || true
