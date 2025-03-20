#!/bin/bash

echo "Building and running all resource blockers"
docker-compose -p resourceblockers up --build -d
echo "Pushing resource blockers to registry"
docker-compose push
echo "Resource blockers are running"