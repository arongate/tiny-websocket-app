FROM python:3.10

COPY . /app

WORKDIR /app

RUN pip install --upgrade pip

RUN pip install -r requirements.txt

EXPOSE 8765

HEALTHCHECK --interval=3s --timeout=2s  CMD curl -f http://localhost:${PORT}/health || exit 1

ENTRYPOINT ["python", "app.py"]