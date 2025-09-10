from fastapi import FastAPI

app = FastAPI(title="User Service")

@app.get("/health")
def health():
    return {"status": "healthy", "service": "user"}

@app.get("/users/{user_id}")
def get_user(user_id: str):
    return {"id": user_id, "name": "John Doe", "email": "john@example.com"}

@app.post("/users")
def create_user():
    return {"id": "456", "message": "User created"}
