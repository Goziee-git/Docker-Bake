# ============================================================================
# DOCKER BAKE CONFIGURATION FILE
# ============================================================================
# This file defines how to build multiple Docker images with shared dependencies
# and optimized caching. Docker Bake uses HCL (HashiCorp Configuration Language)
# which allows for variables, functions, and complex configurations.

# ============================================================================
# VARIABLES SECTION
# ============================================================================
# Variables allow us to parameterize our build configuration, making it
# flexible and reusable across different environments (dev, staging, prod)

variable "REGISTRY" {
  # Default registry where images will be pushed
  # localhost:5000 is commonly used for local development with a local registry
  # In production, this might be something like "your-company.dkr.ecr.us-west-2.amazonaws.com"
  default = "opsmithe"
}

variable "TAG" {
  # Default tag for all images
  # This can be overridden at build time with: docker buildx bake --set *.tags=myapp:v1.2.3
  default = "latest"
}

# ============================================================================
# GROUPS SECTION
# ============================================================================
# Groups allow you to build multiple related targets with a single command
# This is useful for organizing builds by purpose or deployment stage

group "default" {
  # The "default" group builds everything - this runs when you just type "docker buildx bake"
  # Order matters here: "base" will be built first due to dependencies defined below
  targets = ["base", "api", "worker", "frontend"]
}

group "services" {
  # The "services" group builds only the application services, not the base
  # Useful when you know the base hasn't changed: docker buildx bake services
  targets = ["api", "worker", "frontend"]
}

# You could add more groups like:
# group "production" {
#   targets = ["api-multiplatform", "worker-multiplatform", "frontend-multiplatform"]
# }

# ============================================================================
# BASE IMAGE TARGET
# ============================================================================
# This is our foundation image that contains shared dependencies
# All other services will build FROM this image, creating a dependency chain

target "base" {
  # Context is the directory sent to Docker daemon for building
  # Everything in this directory (and subdirectories) is available during build
  context = "./shared"
  
  # Dockerfile specifies which Dockerfile to use (since it's not the default name)
  dockerfile = "Dockerfile.base"
  
  # Tags define how the built image will be named and tagged
  # ${TAG} references the variable defined above
  tags = ["myapp-base:${TAG}"]
  
  # CACHE CONFIGURATION:
  # cache-from tells Docker where to look for existing cache layers
  # type=local means we're using a local directory for cache storage
  cache-from = ["type=local,src=/tmp/.buildx-cache"]
  
  # cache-to tells Docker where to save cache layers after building
  # mode=max saves all intermediate layers (not just the final result)
  # This gives maximum cache reuse but uses more disk space
  cache-to = ["type=local,dest=/tmp/.buildx-cache,mode=max"]
  
  # NOTE: The base image doesn't have depends-on because it's the foundation
  # All other images will depend on this one
}

# ============================================================================
# API SERVICE TARGET
# ============================================================================
# This builds our REST API service that depends on the base image

target "api" {
  # Build context is the api directory
  context = "./api"
  
  # Tag includes the registry prefix for pushing to a registry
  tags = ["${REGISTRY}/myapp-api:${TAG}"]
  
  # DEPENDENCY MANAGEMENT:
  # depends-on ensures the "base" target is built before this one
  # This is crucial because our Dockerfile starts with "FROM myapp-base:latest"
  depends-on = ["base"]
  
  # Same cache configuration as base - all targets share the same cache
  # This means if base image layers are cached, they won't be rebuilt
  cache-from = ["type=local,src=/tmp/.buildx-cache"]
  cache-to = ["type=local,dest=/tmp/.buildx-cache,mode=max"]
  
  # DOCKERFILE EXPECTATIONS:
  # The api/Dockerfile should start with: FROM myapp-base:latest
  # This creates the dependency relationship that makes caching effective
}

# ============================================================================
# WORKER SERVICE TARGET
# ============================================================================
# This builds our background worker service, also depending on base

target "worker" {
  context = "./worker"
  tags = ["${REGISTRY}/myapp-worker:${TAG}"]
  
  # Also depends on base - Docker Bake will ensure base is built first
  depends-on = ["base"]
  
  # Shared cache configuration ensures maximum reuse of base layers
  cache-from = ["type=local,src=/tmp/.buildx-cache"]
  cache-to = ["type=local,dest=/tmp/.buildx-cache,mode=max"]
  
  # PARALLEL BUILDING:
  # Since worker and api both depend only on base (not each other),
  # Docker Bake can build them in parallel after base is complete
}

# ============================================================================
# FRONTEND SERVICE TARGET
# ============================================================================
# This builds our frontend web server, also based on the shared base

target "frontend" {
  context = "./frontend"
  tags = ["${REGISTRY}/myapp-frontend:${TAG}"]
  
  # Same dependency pattern - ensures consistent base across all services
  depends-on = ["base"]
  
  # Same cache configuration for maximum layer reuse
  cache-from = ["type=local,src=/tmp/.buildx-cache"]
  cache-to = ["type=local,dest=/tmp/.buildx-cache,mode=max"]
  
  # BUILD OPTIMIZATION:
  # Since all services share the same base, changes to shared dependencies
  # (like Node.js version, common npm packages) only require rebuilding base once
}

# ============================================================================
# MULTI-PLATFORM TARGETS
# ============================================================================
# These targets demonstrate building for multiple CPU architectures
# Useful for supporting both Intel/AMD (amd64) and Apple Silicon/ARM (arm64)

target "api-multiplatform" {
  # inherits copies all configuration from the "api" target
  # This is like extending or inheriting from a parent class
  inherits = ["api"]
  
  # platforms specifies which CPU architectures to build for
  # Docker Buildx will create separate images for each platform
  platforms = ["linux/amd64", "linux/arm64"]
  
  # USAGE:
  # docker buildx bake api-multiplatform
  # This will build both AMD64 and ARM64 versions of the API service
  
  # PERFORMANCE NOTE:
  # Multi-platform builds are slower because they may require emulation
  # Tools like Depot can provide native builders for faster multi-arch builds
}

target "worker-multiplatform" {
  inherits = ["worker"]
  platforms = ["linux/amd64", "linux/arm64"]
  
  # These targets are useful for:
  # - Production deployments that need to support multiple architectures
  # - Publishing to registries that serve different platforms
  # - Kubernetes clusters with mixed node types
}

target "frontend-multiplatform" {
  inherits = ["frontend"]
  platforms = ["linux/amd64", "linux/arm64"]
  
  # REGISTRY CONSIDERATIONS:
  # When pushed to a registry, multi-platform images create a "manifest list"
  # that automatically serves the correct architecture to each client
}

# ============================================================================
# ADVANCED CACHE STRATEGIES (EXAMPLES)
# ============================================================================
# Here are examples of other cache configurations you might use:

# Example: Registry-based cache (for team sharing)
# target "api-registry-cache" {
#   inherits = ["api"]
#   cache-from = ["type=registry,ref=${REGISTRY}/myapp-cache:latest"]
#   cache-to = ["type=registry,ref=${REGISTRY}/myapp-cache:latest,mode=max"]
# }

# Example: Inline cache (embedded in the image)
# target "api-inline-cache" {
#   inherits = ["api"]
#   cache-to = ["type=inline"]
# }

# Example: GitHub Actions cache (for CI/CD)
# target "api-gha-cache" {
#   inherits = ["api"]
#   cache-from = ["type=gha"]
#   cache-to = ["type=gha,mode=max"]
# }

# ============================================================================
# USAGE EXAMPLES
# ============================================================================
# Here's how you would use this configuration:

# Build everything (default group):
# docker buildx bake

# Build only services (skip base if unchanged):
# docker buildx bake services

# Build specific target:
# docker buildx bake api

# Build with custom tag:
# docker buildx bake --set *.tags=myapp:v1.2.3

# Build and push to registry:
# docker buildx bake --push

# Build multi-platform:
# docker buildx bake api-multiplatform

# Override variables:
# REGISTRY=my-registry.com TAG=v1.0.0 docker buildx bake

# Dry run (see what would be built):
# docker buildx bake --print

# ============================================================================
# CACHE BENEFITS EXPLANATION
# ============================================================================
# The cache configuration in this file provides several benefits:

# 1. LAYER REUSE: If the base image hasn't changed, all services can reuse
#    its cached layers, dramatically speeding up builds

# 2. INCREMENTAL BUILDS: Only changed services need to be rebuilt, while
#    unchanged services use cached versions

# 3. DEPENDENCY OPTIMIZATION: Shared dependencies (Node.js, common packages)
#    are cached once and reused across all services

# 4. TEAM COLLABORATION: With registry cache, team members share cache layers,
#    reducing build times for everyone

# 5. CI/CD EFFICIENCY: Automated builds can leverage cache from previous runs,
#    making deployments faster and more cost-effective
