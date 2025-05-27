FROM python:3.12-bookworm
LABEL authors="Darius Gherca"

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt gunicorn

COPY . .

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app", "--workers", "2", "--log-level", "debug"]
