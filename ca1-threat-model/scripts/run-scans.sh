#!/usr/bin/env bash

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


