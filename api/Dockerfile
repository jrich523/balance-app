
FROM python:3.12-slim

ENV PORT=5000
ENV DOMAIN=0.0.0.0
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

RUN pip3 install --upgrade pip
RUN --mount=type=cache,target=/root/.cache/pip \
    --mount=type=bind,source=./src/requirements.txt,target=requirements.txt \
    python -m pip install -r requirements.txt
#RUN pip install --no-cache-dir -r requirements.txt

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