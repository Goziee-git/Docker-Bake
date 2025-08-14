# Docker Bake & Build Cache Learning Project

This project demonstrates Docker Buildx Bake for building multiple images with shared dependencies and leveraging build cache for efficient image builds.

## Why Docker Bake Matters (The Simple Truth)

**The Problem**: When you have multiple services that use the same dependencies (like Node.js, Python packages, or system libraries), traditional Docker builds waste time and resources by rebuilding the same layers over and over again.

**The Solution**: Docker Bake lets you build a shared base layer once, then build all your services concurrently using that shared layer. This means:

- **Build the shared stuff once** - All common dependencies go into a base image
- **Build services in parallel** - Each service builds at the same time using the shared base
- **Skip rebuilding unchanged parts** - Only rebuild what actually changed
- **Save massive amounts of time** - Instead of 10 minutes per service, build all services in 2 minutes total

**Real Example**: 
- Traditional way: Build API (5 min) → Build Worker (5 min) → Build Frontend (3 min) = **13 minutes**
- Bake way: Build Base (3 min) → Build API + Worker + Frontend together (2 min) = **5 minutes**

When you change just one line of code in the API, traditional builds rebuild everything. Bake only rebuilds the API service using the cached base layer.

## Table of Contents
- [Project Overview](#project-overview)
- [Engineering Benefits](#engineering-benefits)
- [Project Structure](#project-structure)
- [Basic Docker Build vs Bake](#basic-docker-build-vs-bake)
- [Hands-on Examples](#hands-on-examples)
- [Build Cache Strategies](#build-cache-strategies)
- [Using Depot for Enhanced Performance](#using-depot-for-enhanced-performance)
- [Commands Reference](#commands-reference)

## Project Overview

We'll build a simple microservices setup with:
- **Shared Base**: Common Node.js base with shared dependencies
- **API Service**: Express.js REST API
- **Worker Service**: Background job processor
- **Frontend**: Simple static web server

All services share common dependencies (Node.js, some npm packages) making them perfect for demonstrating build cache benefits.

## Engineering Benefits

### Docker Bake Benefits
- **Multi-target builds**: Build multiple related images in one command
- **Dependency management**: Define build dependencies between targets
- **Configuration as code**: Declarative build configuration in HCL/JSON
- **Parallel builds**: Build independent targets simultaneously
- **Consistent environments**: Ensure all team members use same build configuration
- **CI/CD optimization**: Single command for complex multi-image builds

### Build Cache Benefits
- **Faster builds**: Reuse unchanged layers across builds
- **Reduced bandwidth**: Don't rebuild/download unchanged dependencies
- **Developer productivity**: Faster iteration cycles
- **CI/CD efficiency**: Significant time savings in pipelines
- **Cost reduction**: Less compute time = lower costs
- **Consistency**: Same cache across team members and environments

### Depot Benefits
- **Remote build acceleration**: Faster builds with high-performance remote builders
- **Persistent cache**: Cache persists across builds and team members
- **Multi-architecture builds**: Native ARM64/AMD64 builds without emulation
- **Team collaboration**: Shared cache across entire team
- **CI/CD integration**: Drop-in replacement for docker build

## Project Structure

```
docker-bake/
├── README.md
├── docker-bake.hcl              # Bake configuration
├── docker-compose.yml           # Local development
├── shared/
│   ├── Dockerfile.base          # Shared base image
│   └── package.json             # Common dependencies
├── api/
│   ├── Dockerfile
│   ├── package.json
│   ├── server.js
│   └── .dockerignore
├── worker/
│   ├── Dockerfile
│   ├── package.json
│   ├── worker.js
│   └── .dockerignore
├── frontend/
│   ├── Dockerfile
│   ├── index.html
│   ├── package.json
│   └── .dockerignore
└── scripts/
    ├── build-traditional.sh     # Traditional docker build
    ├── build-bake.sh           # Docker bake build
    ├── build-depot.sh          # Depot build
    └── compare-build-times.sh  # Compare build times between traditional and bake
```

## Basic Docker Build vs Bake

### Traditional Docker Build Approach
```bash
# Build each image separately
docker build -t myapp-base ./shared
docker build -t myapp-api ./api
docker build -t myapp-worker ./worker
docker build -t myapp-frontend ./frontend

# Problems:
# - Manual dependency management
# - No parallelization
# - Repetitive commands
# - Hard to maintain consistency
```

### Docker Bake Approach
```bash
# Build all images with dependencies and (push to remote docker registry set in the VARIABLE of the docker-bake.hcl file) docker buildx bake --push

docker buildx bake

# Benefits:
# - Single command
# - Automatic dependency resolution
# - Parallel builds where possible
# - Declarative configuration
```

**NOTE** In the case here we have the docker-compose.yml file and the docker-bake.hcl file, the invocation order of the buildx bake command will attempt to execute the compose file before the bake file so prevent this behaviour you should run the bake command with the specific name of the file you wish to build using docker bake.
example: ```docker buildx bake -f docker-bake.hcl```

In order to use bake images using docker bake, we need to create a temporary directory where build caches will be stored you have to make sure that you have created a buildx.cache/ directory in the /tmp/
```mkdir -p /tmp/.buildx-cache```

```bash
##youll notice that it throws an error here

ERROR: Cache export is not supported for the docker driver.
Switch to a different driver, or turn on the containerd image store, and try again.
```
ISSUE: DOcker default driver dosen't support cache export, so we need to create a buildx instance that supports caching

```bash
#create a builder instance with caching support
====> docker buildx create --name mybuilder --use

#bootstrap the new builder
====> docker buildx inspect --bootstrap

#build images using docker buildx bake with the new builder
====> docker buildx bake --allow=fs=/tmp/.buildx-cache --progress=plain
```

NOTE: bake builds all the images in the bake file in parallel, in the case where there is a shared service that contains args, dependencies that all other services uses, it has to be build first before other services, so we make sure that the share service is first in the bake file

```bash
#Build only the base image first
====> docker buildx bake base --allow=fs=/tmp/.buildx-cache --progress=plain --load

#Now build other services using the docker buildx bake
====> docker buildx bake services --allow=fs=/tmp/.buildx-cache --progress-plain --load
```

NOTE: for the pattern above our docker buildx builder is running in a container and dosen't have access to the local Docker daemon's images, so we can try building out everything at once but ensuring that the base image is available to the builder

```bash
#switching back to the default builder
====> docker buildx use default
#build using bake
====> docker buildx bake --progress=plain
```
One thing i learned here is that when we omit the caching in the docker-bake.hcl file, we created a simplified docker-bake-simple.hcl file and this built the images correctly
```docker buildx bake -f docker-bake-simple.hcl --progress=plain```

## Tag and Push the images to my remote docker registry
firstly ill retag the images and then push them to my remote repository
```docker tag localhost:5000/myapp-worker:latest <repo-name>/myapp-worker:latest && docker push <repo-name>/myapp-worker:latest```
for example: using my docker hub registry username=opsmithe

```docker tag localhost:5000/myapp-worker:latest opsmithe/myapp-worker:latest && docker push opsmithe/myapp-worker:latest```

do same for all other images

## TEST
Testing the API health endpoint
```curl -s http://localhost:3000/health```
Testing the API data endpoint
```curl -s http://localhost:3000/data```
Test the frontend 
```curl -s http://localhost:8080 | head -10```
Too see the worker logs checking if its working correctly
```docker-compose logs worker --tail=5```

## Build Cache Strategies

### 1. Local Cache
```bash
# Build with local cache
docker buildx bake --cache-from=type=local,src=/tmp/.buildx-cache --cache-to=type=local,dest=/tmp/.buildx-cache,mode=max
```

### 2. Registry Cache
```bash
# Push cache to registry
docker buildx bake --cache-from=type=registry,ref=myregistry/myapp:cache --cache-to=type=registry,ref=myregistry/myapp:cache,mode=max
```

### 3. Inline Cache
```bash
# Embed cache in image
docker buildx bake --cache-to=type=inline
```

### 4. GitHub Actions Cache
```yaml
# In GitHub Actions
- name: Build with cache
  run: |
    docker buildx bake \
      --cache-from=type=gha \
      --cache-to=type=gha,mode=max
```

## Using Depot for Enhanced Performance

### Setup Depot

1. **Install Depot CLI**:
```bash
curl -L https://depot.dev/install-cli.sh | sh
```

2. **Login to Depot**:
```bash
depot login
```

3. **Create a Project**:
```bash
depot init
```

### Depot Bake Configuration

Create **depot.json**:
```json
{
  "id": "your-project-id",
  "builds": {
    "default": {
      "dockerfile": "docker-bake.hcl"
    }
  }
}
```

### Enhanced Bake with Depot

**docker-bake.depot.hcl**:
```hcl
# Depot-optimized bake configuration
variable "DEPOT_PROJECT_ID" {
  default = "your-project-id"
}

target "base" {
  context = "./shared"
  dockerfile = "Dockerfile.base"
  tags = ["myapp-base:latest"]
  cache-from = ["type=depot"]
  cache-to = ["type=depot"]
}

target "api" {
  context = "./api"
  tags = ["myapp-api:latest"]
  depends-on = ["base"]
  cache-from = ["type=depot"]
  cache-to = ["type=depot"]
  platforms = ["linux/amd64", "linux/arm64"]
}

# ... other targets with depot cache
```

### Depot Benefits in Practice

1. **Persistent Cache**: Cache persists across builds and team members
2. **Fast Builders**: High-performance remote builders
3. **Multi-arch**: Native ARM64/AMD64 without emulation
4. **Team Sharing**: Shared cache across entire team

## Commands Reference

### Basic Commands

```bash
# Build all targets
docker buildx bake

# Build specific target
docker buildx bake api

# Build specific group
docker buildx bake services

# Build with variables
docker buildx bake --set *.tags=myapp:v1.0.0

# Dry run (show what would be built)
docker buildx bake --print

# Build and push
docker buildx bake --push
```

### Cache Commands

```bash
# Build with local cache
docker buildx bake --cache-from=type=local,src=/tmp/.buildx-cache

# Build with registry cache
docker buildx bake --cache-from=type=registry,ref=myregistry/cache

# Prune build cache
docker buildx prune

# Show cache usage
docker system df
```

### Depot Commands

```bash
# Build with depot
depot bake

# Build specific target
depot bake api

# Build with custom project
depot bake --project=your-project-id

# Show depot status
depot status
```

## Testing the Setup

### 1. Build Time Comparison (Recommended First Step)
```bash
# Run the comprehensive build time comparison
./scripts/compare-build-times.sh
```
This script will:
- Build the frontend service using traditional Docker build
- Build the same service using Docker Bake
- Test rebuild performance after simulating a code change
- Show detailed timing results and efficiency gains

### 2. Traditional Build Test
```bash
chmod +x scripts/*.sh
./scripts/build-traditional.sh
```

### 3. Bake Build Test
```bash
./scripts/build-bake.sh
```

### 5. Run the Application
```bash
docker-compose up -d
```

Visit:
- Frontend: http://localhost:8080
- API: http://localhost:3000/health

### 6. Test Cache Efficiency
```bash
# Make a small change to one service
echo "console.log('Cache test');" >> api/server.js

# Rebuild - should be much faster
./scripts/build-bake.sh
```

## Performance Comparison

Run both build scripts and compare:
- **First build**: Traditional vs Bake (similar times)
- **Subsequent builds**: Bake with cache (significantly faster)
- **Partial changes**: Only affected services rebuild

## Next Steps

1. Experiment with different cache strategies
2. Try multi-platform builds
3. Integrate with CI/CD pipelines
4. Explore Depot for team collaboration
5. Add more complex dependencies to see cache benefits

This project demonstrates the power of Docker Bake and build cache for efficient multi-service applications!
