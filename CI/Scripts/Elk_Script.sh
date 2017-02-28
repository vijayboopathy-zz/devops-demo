#!/bin/bash
apt install git
cd /home/ubuntu
if ls 2> /dev/null | grep -q -i "docker-elk"; then
  echo "ELK repo is already cloned"
else
  git clone https://github.com/deviantony/docker-elk.git
fi
cd /home/ubuntu/docker-elk
sysctl -w vm.max_map_count=262144
docker-compose up -d
