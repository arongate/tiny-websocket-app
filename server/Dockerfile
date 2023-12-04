FROM python:3.10

COPY . /app

WORKDIR /app/server

RUN pip install -r requirements.txt

EXPOSE 8765

ENV PORT 8765

ENTRYPOINT ["python", "app.py"]