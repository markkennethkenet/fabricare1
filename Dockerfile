FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    YOLO_CONFIG_DIR=/tmp/ultralytics

WORKDIR /app
RUN apt-get update \
    && apt-get install -y --no-install-recommends libgl1 libglib2.0-0 libxcb1 \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt requirements-hosting.txt ./
RUN python -m pip install -r requirements-hosting.txt

COPY assessment.py assessment_config.json auth_routes.py database.py db_config.py ./
COPY fabricare_api.py image_processing.py model_runtime.py serve_api.py ./
COPY model/ ./model/

CMD ["python", "serve_api.py"]
