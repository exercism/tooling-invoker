#############
## Stage 1 ##
#############
FROM exercism/setup as common
FROM ruby:3.1.0-alpine3.15 as gembuilder

RUN apk add --no-cache --update build-base cmake openssl-dev

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./
RUN gem install bundler:2.3.4 && \
    bundle install

#############
## Stage 2 ##
#############
FROM ruby:3.1.0-alpine3.15

RUN apk add --no-cache --update git bash docker

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./
RUN gem install bundler:2.3.4

COPY --from=gembuilder /usr/local/bundle/ /usr/local/bundle/
COPY --from=common /shell /
COPY . .

ENV CONTAINER_NAME=tooling-invoker

ENTRYPOINT ./bin/run-local
