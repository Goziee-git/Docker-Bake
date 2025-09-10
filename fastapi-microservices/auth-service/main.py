from fastapi import FastAPI

app = FastAPI(title="Auth Service")

@app.get("/health")
def health():
    return {"status": "healthy", "service": "auth"}

@app.post("/login")
def login():
    return {"token": "mock-jwt-token"}

@app.post("/validate")
def validate():
    return {"valid": True, "user_id": "123"}
