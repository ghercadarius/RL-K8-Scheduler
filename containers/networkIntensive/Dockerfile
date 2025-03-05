FROM python:3.12-bookworm
LABEL authors="Darius Gherca"

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .


CMD ["python", "app.py"]