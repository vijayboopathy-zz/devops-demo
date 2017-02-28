#!/bin/bash
apt install git -y
cd /home/ubuntu
if ls 2> /dev/null | grep -q -i "prometheus"; then
  echo "Prometheus repo is already cloned"
else
    git clone https://github.com/vegasbrianc/prometheus.git
fi
cd /home/ubuntu/prometheus
docker-compose up -d

