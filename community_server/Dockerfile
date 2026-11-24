FROM python:3.12-slim
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1 MYBALANCE_DB=/data/community.sqlite3
WORKDIR /app
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
COPY server.py start.py ./
RUN mkdir -p /data
EXPOSE 8000
CMD ["python", "start.py"]
