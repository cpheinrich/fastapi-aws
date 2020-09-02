FROM tiangolo/uvicorn-gunicorn-fastapi:python3.7
WORKDIR /app/

COPY ./app /app
COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt