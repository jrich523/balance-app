
FROM python:3.11-slim

ENV PORT=5000
ENV DOMAIN=0.0.0.0
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

COPY ./src/requirements.txt /app/requirements.txt

RUN pip3 install --upgrade pip
RUN python -m pip install -r requirements.txt

ARG UID=10001
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid "${UID}" \
    appuser
USER appuser

COPY ./src /app/


EXPOSE 5000

CMD [ "python3", "/app/app.py" ]