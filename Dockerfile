FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=4000

WORKDIR /app

COPY requirements.txt ./
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

COPY . ./

EXPOSE 4000

CMD ["sh", "-c", "if [ -f /app/.env ]; then set -a; . /app/.env; set +a; fi; exec litellm --config /app/config.yaml --host 0.0.0.0 --port ${PORT:-4000}"]
