FROM elixir:1.9-alpine as build

ARG DATABASE_URL
ARG SECRET_KEY_BASE
ARG POOL_SIZE
ENV DATABASE_URL=${DATABASE_URL}
ENV SECRET_KEY_BASE=${SECRET_KEY_BASE}
ENV POOL_SIZE=${POOL_SIZE}
ENV MIX_ENV=prod

RUN apk add --update git build-base

RUN mkdir /app
WORKDIR /app

COPY mix.exs mix.lock ./
COPY config config

RUN mix local.hex --force && mix local.rebar --force

RUN mix deps.get --only prod
RUN mix deps.compile

COPY priv priv
COPY lib lib
RUN mix compile

COPY rel rel
RUN mix release

FROM alpine:3.9 AS app

RUN apk add --update bash openssl

RUN mkdir /app
WORKDIR /app

COPY --from=build /app/_build/prod/rel/stonex /app
RUN chown -R nobody: /app
RUN ls
USER nobody

ENV HOME=/app

CMD ["/app/bin/stonex", "start"]