#!/bin/bash

echo "Deleting resource blocker container"
docker rm -f "resourceblocker"
echo "Deleting volumes"
docker-compose down -v --remove-orphans
