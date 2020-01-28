ARG ELIXIR_VERSION=1.10
ARG DEBIAN_VERSION=buster-slim

#----------------------------------------------------------------#
FROM elixir:${ELIXIR_VERSION} AS builder

# install build dependencies
RUN apt-get update &&\
    apt-get install -y libsodium-dev

# prepare build dir
RUN mkdir /app
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force &&\
    mix local.rebar --force

# set build ENV
ENV MIX_ENV=prod

COPY config ./config
COPY lib ./lib
COPY mix.exs .
COPY mix.lock .

RUN mix deps.get --only prod &&\
    mix deps.compile

# build and release project
RUN mix release

#----------------------------------------------------------------#
FROM debian:${DEBIAN_VERSION}
RUN apt-get update &&\
    apt-get install -y libsodium-dev openssl

RUN useradd --create-home app
WORKDIR /home/app
COPY --from=builder /app/_build/prod/rel/notary ./
RUN chown -R app: ./
USER app

EXPOSE 3000

# docker run\
#   --env NOTARY_HTTP_PORT=3000\
#   --env NOTARY_SECRET_PATH=/notary_conf/secret\
#   --env NOTARY_OIDC_JSON_PATH=/notary_conf/oidc.json\
#   -v /host/path/to/conf_dir:/notary_conf\
#   -p 3000:3000 -ti notary

ENTRYPOINT ["./bin/notary"]
CMD ["start"]

#----------------------------------------------------------------#
