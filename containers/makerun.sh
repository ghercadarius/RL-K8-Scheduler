#!/bin/bash

cd cpuIntensive
docker build -t cpuintensive .
docker run -d --cpuset-cpus="0,1,2,3" -p 127.0.0.1:5000:5000 cpuintensive
echo "made and ran cpu blocker"

cd ../ramIntensive
docker build -t ramintensive .
docker run -d -p 127.0.0.1:5001:5001 ramintensive
echo "made and ran ram blocker"

cd ../diskIntensive
docker build -t diskintensive .
docker run -d -p 127.0.0.1:5002:5002 -v disk_data:/data diskintensive
echo "made and ran disk blocker"

cd ../networkIntensive
docker build -t networkintensive .
docker run -d -p 127.0.0.1:5003:5003 networkintensive
echo "made and ran network blocker"
