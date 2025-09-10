# Docker Bake HCL Configuration Guide for FastAPI

## HCL File Structure

The `docker-bake.hcl` file consists of four main components:

### 1. Variables
```hcl
variable "REGISTRY" {
  default = "localhost:5000"
}
```
- Define configurable values
- Can be overridden at build time: `--set *.args.REGISTRY=myregistry.com`

### 2. Targets
```hcl
target "fastapi-base" {
  context = "./shared"
  dockerfile = "Dockerfile.base"
  tags = ["${REGISTRY}/myapp-fastapi-base:${TAG}"]
  depends-on = []
}
```

**Key Target Properties:**
- `context`: Build context directory
- `dockerfile`: Dockerfile path (optional if named "Dockerfile")
- `tags`: Image tags (supports variable interpolation)
- `depends-on`: Build dependencies (ensures order)
- `cache-from/cache-to`: Cache configuration
- `platforms`: Multi-architecture builds

### 3. Dependencies
```hcl
target "auth-service" {
  depends-on = ["fastapi-base"]
}
```
- Ensures `fastapi-base` builds before `auth-service`
- Enables shared layer reuse

### 4. Groups
```hcl
group "services" {
  targets = ["auth-service", "user-service", "gateway"]
}
```
- Logical groupings for batch operations
- `docker buildx bake services` builds all services

## Cache Strategies

### Local Cache
```hcl
cache-from = ["type=local,src=/tmp/.buildx-cache"]
cache-to = ["type=local,dest=/tmp/.buildx-cache,mode=max"]
```

### Registry Cache
```hcl
cache-from = ["type=registry,ref=myregistry/cache:latest"]
cache-to = ["type=registry,ref=myregistry/cache:latest,mode=max"]
```

### Inline Cache
```hcl
cache-to = ["type=inline"]
```

## Build Commands

```bash
# Build everything
docker buildx bake

# Build specific target
docker buildx bake fastapi-base

# Build group
docker buildx bake services

# Override variables
docker buildx bake --set *.args.TAG=v1.0.0

# Build and push
docker buildx bake --push

# Dry run
docker buildx bake --print
```

## Advanced Configuration

### Multi-platform builds
```hcl
target "auth-service" {
  platforms = ["linux/amd64", "linux/arm64"]
}
```

### Build arguments
```hcl
target "auth-service" {
  args = {
    PYTHON_VERSION = "3.11"
    BUILD_ENV = "production"
  }
}
```

### Output configuration
```hcl
target "auth-service" {
  output = ["type=docker"]  # Load to local Docker
  # output = ["type=registry"] # Push to registry
}
```
