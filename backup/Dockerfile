FROM python:3.11-alpine

# Install postgresql client (pg_dump), tzdata for accurate timezone calculation, and gzip
RUN apk add --no-cache postgresql-client tzdata gzip bash

ENV PYTHONUNBUFFERED=1
WORKDIR /app

# Install python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Create backup and credentials directories
RUN mkdir -p /backups /app/credentials

# Copy application scripts
COPY backup.py get_token.py ./

CMD ["python", "-u", "backup.py"]
