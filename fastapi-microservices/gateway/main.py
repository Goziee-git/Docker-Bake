from fastapi import FastAPI
import httpx

app = FastAPI(title="API Gateway")

@app.get("/health")
def health():
    return {"status": "healthy", "service": "gateway"}

@app.get("/auth/{path:path}")
async def auth_proxy(path: str):
    async with httpx.AsyncClient() as client:
        response = await client.get(f"http://auth-service:8000/{path}")
        return response.json()

@app.get("/users/{path:path}")
async def user_proxy(path: str):
    async with httpx.AsyncClient() as client:
        response = await client.get(f"http://user-service:8000/{path}")
        return response.json()
