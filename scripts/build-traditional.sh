#!/bin/bash
set -e

echo "Building with traditional Docker commands..."
echo "============================================"

# Record start time
start_time=$(date +%s)

# Build base image
echo "Building base image..."
docker build -t myapp-base:latest ./shared -f ./shared/Dockerfile.base

# Build service images
echo "Building API service..."
docker build -t localhost:5000/myapp-api:latest ./api

echo "Building worker service..."
docker build -t localhost:5000/myapp-worker:latest ./worker

echo "Building frontend service..."
docker build -t localhost:5000/myapp-frontend:latest ./frontend

# Calculate build time
end_time=$(date +%s)
build_time=$((end_time - start_time))

echo "Traditional build completed in ${build_time} seconds"
echo "Images built:"
docker images | grep myapp
