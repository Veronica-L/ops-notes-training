FROM python:3.12-slim
WORKDIR /app
ENV PYTHONDONTWRITEBYTECODE=1 PYTHONUNBUFFERED=1
RUN groupadd --gid 10001 app && useradd --uid 10001 --gid 10001 --no-create-home app \
    && mkdir /data && chown 10001:10001 /data
COPY app.py VERSION ./
USER 10001:10001
EXPOSE 8000
CMD ["python", "app.py"]
