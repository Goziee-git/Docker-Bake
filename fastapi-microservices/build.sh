#!/bin/bash

echo "Building FastAPI microservices with Docker Bake..."

# Ensure cache directory exists
mkdir -p /tmp/.buildx-cache

# Create builder if it doesn't exist
if ! docker buildx ls | grep -q mybuilder; then
    echo "Creating buildx builder..."
    docker buildx create --name mybuilder --use
    docker buildx inspect --bootstrap
fi

# Build all services
echo "Building all services..."
docker buildx bake -f docker-bake.hcl --progress=plain

echo "Build complete! Run 'docker-compose up -d' to start services."
