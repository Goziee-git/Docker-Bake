# Docker Bake & Build Cache Learning Project

This project demonstrates Docker Buildx Bake for building multiple images with shared dependencies and leveraging build cache for efficient image builds.

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
    └── build-depot.sh          # Depot build
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
# Build all images with dependencies
docker buildx bake

# Benefits:
# - Single command
# - Automatic dependency resolution
# - Parallel builds where possible
# - Declarative configuration
```

## Hands-on Examples

### Step 1: Setup Project Files

First, let's create our basic application files:

```bash
# Navigate to project directory
cd docker-bake

# Create all necessary directories
mkdir -p shared api worker frontend scripts
```

### Step 2: Create Shared Base

The shared base contains common dependencies used by multiple services.

**shared/package.json**:
```json
{
  "name": "shared-base",
  "version": "1.0.0",
  "dependencies": {
    "lodash": "^4.17.21",
    "moment": "^2.29.4",
    "axios": "^1.6.0"
  }
}
```

**shared/Dockerfile.base**:
```dockerfile
FROM node:18-alpine

# Install common system dependencies
RUN apk add --no-cache curl

# Set working directory
WORKDIR /app

# Copy and install shared dependencies
COPY package.json ./
RUN npm install --production

# This layer will be cached and reused by other services
RUN echo "Shared base layer created at $(date)" > /app/build-info.txt
```

### Step 3: Create API Service

**api/package.json**:
```json
{
  "name": "api-service",
  "version": "1.0.0",
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5"
  },
  "scripts": {
    "start": "node server.js"
  }
}
```

**api/server.js**:
```javascript
const express = require('express');
const cors = require('cors');
const _ = require('lodash');
const moment = require('moment');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: moment().format(),
    service: 'api'
  });
});

app.get('/data', (req, res) => {
  const data = _.range(1, 11).map(i => ({
    id: i,
    name: `Item ${i}`,
    created: moment().subtract(i, 'days').format()
  }));
  
  res.json(data);
});

app.listen(PORT, () => {
  console.log(`API Server running on port ${PORT}`);
});
```

**api/Dockerfile**:
```dockerfile
# Use our shared base
FROM myapp-base:latest

# Copy API-specific dependencies
COPY package.json ./
RUN npm install --production

# Copy application code
COPY server.js ./

# Expose port
EXPOSE 3000

# Start the application
CMD ["npm", "start"]
```

**api/.dockerignore**:
```
node_modules
npm-debug.log
.git
.gitignore
README.md
```

### Step 4: Create Worker Service

**worker/package.json**:
```json
{
  "name": "worker-service",
  "version": "1.0.0",
  "dependencies": {
    "node-cron": "^3.0.3"
  },
  "scripts": {
    "start": "node worker.js"
  }
}
```

**worker/worker.js**:
```javascript
const cron = require('node-cron');
const _ = require('lodash');
const moment = require('moment');
const axios = require('axios');

console.log('Worker service starting...');

// Simulate background job every 30 seconds
cron.schedule('*/30 * * * * *', async () => {
  const timestamp = moment().format();
  const randomData = _.random(1, 100);
  
  console.log(`[${timestamp}] Processing job with data: ${randomData}`);
  
  // Simulate some work
  await new Promise(resolve => setTimeout(resolve, 1000));
  
  console.log(`[${timestamp}] Job completed`);
});

console.log('Worker service started. Jobs scheduled.');

// Keep the process running
process.on('SIGTERM', () => {
  console.log('Worker service shutting down...');
  process.exit(0);
});
```

**worker/Dockerfile**:
```dockerfile
# Use our shared base
FROM myapp-base:latest

# Copy worker-specific dependencies
COPY package.json ./
RUN npm install --production

# Copy application code
COPY worker.js ./

# Start the application
CMD ["npm", "start"]
```

**worker/.dockerignore**:
```
node_modules
npm-debug.log
.git
.gitignore
README.md
```

### Step 5: Create Frontend Service

**frontend/package.json**:
```json
{
  "name": "frontend-service",
  "version": "1.0.0",
  "dependencies": {
    "express": "^4.18.2"
  },
  "scripts": {
    "start": "node server.js"
  }
}
```

**frontend/index.html**:
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Docker Bake Demo</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 800px; margin: 0 auto; }
        .service { background: #f5f5f5; padding: 20px; margin: 20px 0; border-radius: 8px; }
        button { background: #007cba; color: white; padding: 10px 20px; border: none; border-radius: 4px; cursor: pointer; }
        button:hover { background: #005a87; }
        #data { margin-top: 20px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Docker Bake Demo Application</h1>
        
        <div class="service">
            <h2>API Service</h2>
            <button onclick="fetchData()">Fetch Data from API</button>
            <div id="data"></div>
        </div>
        
        <div class="service">
            <h2>Build Information</h2>
            <p>This application demonstrates Docker Bake with shared build cache.</p>
            <p>All services share a common base image with shared dependencies.</p>
        </div>
    </div>

    <script>
        async function fetchData() {
            try {
                const response = await fetch('/api/data');
                const data = await response.json();
                document.getElementById('data').innerHTML = 
                    '<pre>' + JSON.stringify(data, null, 2) + '</pre>';
            } catch (error) {
                document.getElementById('data').innerHTML = 
                    '<p style="color: red;">Error: ' + error.message + '</p>';
            }
        }
    </script>
</body>
</html>
```

**frontend/server.js**:
```javascript
const express = require('express');
const path = require('path');
const axios = require('axios');

const app = express();
const PORT = process.env.PORT || 8080;
const API_URL = process.env.API_URL || 'http://api:3000';

// Serve static files
app.use(express.static(__dirname));

// Proxy API requests
app.get('/api/*', async (req, res) => {
  try {
    const apiPath = req.path.replace('/api', '');
    const response = await axios.get(`${API_URL}${apiPath}`);
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ error: 'API request failed' });
  }
});

app.listen(PORT, () => {
  console.log(`Frontend server running on port ${PORT}`);
});
```

**frontend/Dockerfile**:
```dockerfile
# Use our shared base
FROM myapp-base:latest

# Copy frontend-specific dependencies
COPY package.json ./
RUN npm install --production

# Copy application files
COPY server.js ./
COPY index.html ./

# Expose port
EXPOSE 8080

# Start the application
CMD ["npm", "start"]
```

**frontend/.dockerignore**:
```
node_modules
npm-debug.log
.git
.gitignore
README.md
```

### Step 6: Create Docker Bake Configuration

**docker-bake.hcl**:
```hcl
# Define variables
variable "REGISTRY" {
  default = "localhost:5000"
}

variable "TAG" {
  default = "latest"
}

# Define groups for different build scenarios
group "default" {
  targets = ["base", "api", "worker", "frontend"]
}

group "services" {
  targets = ["api", "worker", "frontend"]
}

# Shared base image
target "base" {
  context = "./shared"
  dockerfile = "Dockerfile.base"
  tags = ["myapp-base:${TAG}"]
  cache-from = ["type=local,src=/tmp/.buildx-cache"]
  cache-to = ["type=local,dest=/tmp/.buildx-cache,mode=max"]
}

# API service
target "api" {
  context = "./api"
  tags = ["${REGISTRY}/myapp-api:${TAG}"]
  depends-on = ["base"]
  cache-from = ["type=local,src=/tmp/.buildx-cache"]
  cache-to = ["type=local,dest=/tmp/.buildx-cache,mode=max"]
}

# Worker service
target "worker" {
  context = "./worker"
  tags = ["${REGISTRY}/myapp-worker:${TAG}"]
  depends-on = ["base"]
  cache-from = ["type=local,src=/tmp/.buildx-cache"]
  cache-to = ["type=local,dest=/tmp/.buildx-cache,mode=max"]
}

# Frontend service
target "frontend" {
  context = "./frontend"
  tags = ["${REGISTRY}/myapp-frontend:${TAG}"]
  depends-on = ["base"]
  cache-from = ["type=local,src=/tmp/.buildx-cache"]
  cache-to = ["type=local,dest=/tmp/.buildx-cache,mode=max"]
}

# Multi-platform builds
target "api-multiplatform" {
  inherits = ["api"]
  platforms = ["linux/amd64", "linux/arm64"]
}

target "worker-multiplatform" {
  inherits = ["worker"]
  platforms = ["linux/amd64", "linux/arm64"]
}

target "frontend-multiplatform" {
  inherits = ["frontend"]
  platforms = ["linux/amd64", "linux/arm64"]
}
```

### Step 7: Create Build Scripts

**scripts/build-traditional.sh**:
```bash
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
```

**scripts/build-bake.sh**:
```bash
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
```

**scripts/build-depot.sh**:
```bash
#!/bin/bash
set -e

echo "Building with Depot..."
echo "====================="

# Check if depot is installed
if ! command -v depot &> /dev/null; then
    echo "Depot CLI not found. Installing..."
    curl -L https://depot.dev/install-cli.sh | sh
fi

# Record start time
start_time=$(date +%s)

# Build with depot (requires depot project setup)
# Replace 'your-project-id' with your actual Depot project ID
depot bake --project=your-project-id

# Calculate build time
end_time=$(date +%s)
build_time=$((end_time - start_time))

echo "Depot build completed in ${build_time} seconds"
echo "Images built:"
docker images | grep myapp
```

### Step 8: Create Docker Compose for Testing

**docker-compose.yml**:
```yaml
version: '3.8'

services:
  api:
    image: localhost:5000/myapp-api:latest
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=development
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  worker:
    image: localhost:5000/myapp-worker:latest
    environment:
      - NODE_ENV=development
    depends_on:
      - api

  frontend:
    image: localhost:5000/myapp-frontend:latest
    ports:
      - "8080:8080"
    environment:
      - API_URL=http://api:3000
      - NODE_ENV=development
    depends_on:
      - api
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080"]
      interval: 30s
      timeout: 10s
      retries: 3

networks:
  default:
    name: myapp-network
```

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

### 1. Traditional Build Test
```bash
chmod +x scripts/*.sh
./scripts/build-traditional.sh
```

### 2. Bake Build Test
```bash
./scripts/build-bake.sh
```

### 3. Run the Application
```bash
docker-compose up -d
```

Visit:
- Frontend: http://localhost:8080
- API: http://localhost:3000/health

### 4. Test Cache Efficiency
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
