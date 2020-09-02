from fastapi import APIRouter

router = APIRouter()


@router.get("/")
async def example_get():
    return {"Hello": "From example_get"}
