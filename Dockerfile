FROM elixir:1.16.3-alpine

RUN apk add inotify-tools \
  postgresql-client

RUN mix local.hex --force && \
    mix archive.install hex phx_new --force && \
    mix local.rebar --force

RUN mkdir /app

WORKDIR /app

RUN adduser -D app
ENV USER app
USER app

EXPOSE 4000
