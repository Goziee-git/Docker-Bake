# Simple Docker Bake configuration without cache
variable "REGISTRY" {
  default = "localhost:5000"
}

variable "TAG" {
  default = "latest"
}

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
}

# API service
target "api" {
  context = "./api"
  tags = ["${REGISTRY}/myapp-api:${TAG}"]
  depends-on = ["base"]
}

# Worker service
target "worker" {
  context = "./worker"
  tags = ["${REGISTRY}/myapp-worker:${TAG}"]
  depends-on = ["base"]
}

# Frontend service
target "frontend" {
  context = "./frontend"
  tags = ["${REGISTRY}/myapp-frontend:${TAG}"]
  depends-on = ["base"]
}
