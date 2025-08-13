# Quick Start Guide

## Prerequisites
- Docker with Buildx enabled
- Docker Compose

## Quick Demo

### 1. Traditional Build (for comparison)
```bash
cd /home/prospa/docker-bake
./scripts/build-traditional.sh
```

### 2. Docker Bake Build
```bash
./scripts/build-bake.sh
```

### 3. Run the Application
```bash
docker-compose up -d
```

### 4. Test the Application
- Frontend: http://localhost:8080
- API Health: http://localhost:3000/health
- API Data: http://localhost:3000/data

### 5. Test Cache Efficiency
```bash
# Make a small change
echo "console.log('Cache test');" >> api/server.js

# Rebuild - notice the speed difference
./scripts/build-bake.sh
```

### 6. Clean Up
```bash
docker-compose down
docker system prune -f
```

## Key Commands

```bash
# Build all services
docker buildx bake

# Build specific service
docker buildx bake api

# Build with custom tag
docker buildx bake --set *.tags=myapp:v2.0.0

# Show what would be built (dry run)
docker buildx bake --print

# Build and push to registry
docker buildx bake --push
```

## Cache Commands

```bash
# View cache usage
docker system df

# Clean build cache
docker buildx prune

# Clean everything
docker system prune -a
```
