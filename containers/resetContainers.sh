#!/bin/bash

docker rm -v -f $(docker ps -qa)
echo "Deleted all containers"
