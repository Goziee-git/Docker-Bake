#!/bin/bash
set -e

echo "Building with Docker Bake..."
echo "============================"

# Record start time
start_time=$(date +%s)

# Ensure buildx cache directory exists
mkdir -p /tmp/.buildx-cache

# Build all targets
docker buildx bake --progress=plain

# Calculate build time
end_time=$(date +%s)
build_time=$((end_time - start_time))

echo "Bake build completed in ${build_time} seconds"
echo "Images built:"
docker images | grep myapp
