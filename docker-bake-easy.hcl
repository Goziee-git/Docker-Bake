variable "REGISTRY" { default = "opsmithe" }

variable "LABEL" { default = "myapp" }
variable "PLATFORM" { default = "linux/amd64,linux/arm64" }

variable "TAG" { default = "latest" }

group "default" { targets  = ["base", "api"] }

target "base" {
    context = "./shared"
    dockerfile = "Dockerfile.base"
    tags = ["myapp-base:${TAG}"]
    cache-from = ["type=local,src=/tmp/.buildx-cache"]
    cache-to = ["type=local,dest=/tmp/.buildx-cache,mode=max"]
}

target "api" {
    context = "./api"
    dockerfile = "Dockerfile"
    tags = ["${REGISTRY}/${LABEL}-api:${TAG}"]
    cache-from = ["type=local,src=/tmp/.buildx-cache"]
    cache-to = ["type=local,dest=/tmp/.buildx-cache,mode=max"]
    depends_on = ["base"]
}