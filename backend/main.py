from fastapi import FastAPI

app = FastAPI(title="Re:view")

@app.get("/")
def root():
    return {"message": "Re:view"}