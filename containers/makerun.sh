#!/bin/bash

echo "Building and running resource blocker"
docker compose -p resourceblocker up --build -d
echo "Pushing resource blocker to registry"
docker compose push
echo "Resource blockers are running"