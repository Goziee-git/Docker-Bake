# FastAPI Microservices with Docker Bake

This directory demonstrates building FastAPI microservices using Docker Bake with shared dependencies and efficient caching.

## Architecture

- **Shared Base**: Common Python base with FastAPI and shared dependencies
- **Auth Service**: User authentication API
- **User Service**: User management API
- **Gateway**: API gateway routing requests

## Structure

```
fastapi-microservices/
├── docker-bake.hcl          # Bake configuration
├── shared/
│   ├── Dockerfile.base      # Shared Python/FastAPI base
│   └── requirements.txt     # Common dependencies
├── auth-service/
│   ├── Dockerfile
│   ├── requirements.txt
│   └── main.py
├── user-service/
│   ├── Dockerfile
│   ├── requirements.txt
│   └── main.py
├── gateway/
│   ├── Dockerfile
│   ├── requirements.txt
│   └── main.py
└── docker-compose.yml       # Local development
```

## Quick Start

```bash
# Build all services
docker buildx bake -f docker-bake.hcl

# Run locally
docker-compose up -d

# Test endpoints
curl http://localhost:8000/health  # Gateway
curl http://localhost:8001/health  # Auth
curl http://localhost:8002/health  # User
```

## HCL Configuration Explained

The `docker-bake.hcl` file defines:
1. **Variables**: Configurable values (registry, tags)
2. **Base target**: Shared Python/FastAPI foundation
3. **Service targets**: Individual microservices
4. **Groups**: Logical groupings for batch operations
5. **Cache strategies**: Efficient layer reuse
