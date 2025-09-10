# Variables for configuration
variable "REGISTRY" {
  default = "localhost:5000"
}

variable "TAG" {
  default = "latest"
}

# Shared base image target
target "fastapi-base" {
  context = "./shared"
  dockerfile = "Dockerfile.base"
  tags = ["${REGISTRY}/myapp-fastapi-base:${TAG}"]
  cache-from = ["type=local,src=/tmp/.buildx-cache"]
  cache-to = ["type=local,dest=/tmp/.buildx-cache,mode=max"]
}

# Auth service target
target "auth-service" {
  context = "./auth-service"
  tags = ["${REGISTRY}/myapp-auth:${TAG}"]
  depends-on = ["fastapi-base"]
  cache-from = ["type=local,src=/tmp/.buildx-cache"]
  cache-to = ["type=local,dest=/tmp/.buildx-cache,mode=max"]
}

# User service target
target "user-service" {
  context = "./user-service"
  tags = ["${REGISTRY}/myapp-user:${TAG}"]
  depends-on = ["fastapi-base"]
  cache-from = ["type=local,src=/tmp/.buildx-cache"]
  cache-to = ["type=local,dest=/tmp/.buildx-cache,mode=max"]
}

# Gateway service target
target "gateway" {
  context = "./gateway"
  tags = ["${REGISTRY}/myapp-gateway:${TAG}"]
  depends-on = ["fastapi-base"]
  cache-from = ["type=local,src=/tmp/.buildx-cache"]
  cache-to = ["type=local,dest=/tmp/.buildx-cache,mode=max"]
}

# Group for building all services
group "services" {
  targets = ["auth-service", "user-service", "gateway"]
}

# Group for building everything
group "default" {
  targets = ["fastapi-base", "auth-service", "user-service", "gateway"]
}
