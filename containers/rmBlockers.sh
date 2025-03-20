#!/bin/bash

echo "Deleting docker compose containers"
docker rm -f "diskintensive"
docker rm -f "cpuintensive"
docker rm -f "networkintensive"
docker rm -f "ramintensive"
echo "Deleting volumes"
docker-compose down -v --remove-orphans