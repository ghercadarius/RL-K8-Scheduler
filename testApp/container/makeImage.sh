#!/bin/bash

# Variables
DOCKERHUB_USER="ghercadarius"
IMAGE_NAME="testapp"
TAG="latest"

# Build the Docker image
docker build -t $DOCKERHUB_USER/$IMAGE_NAME:$TAG .

# Push the image to Docker Hub
docker push $DOCKERHUB_USER/$IMAGE_NAME:$TAG