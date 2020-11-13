#############
## Stage 1 ##
#############
FROM exercism/setup as common
FROM ruby:2.6.6-alpine3.12 as gembuilder

RUN apk add --no-cache --update build-base cmake

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./
RUN gem install bundler:2.1.4 && \
    bundle install

#############
## Stage 2 ##
#############
FROM ruby:2.6.6-alpine3.12

RUN apk add --no-cache --update git bash

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./
RUN gem install bundler:2.1.4

COPY --from=gembuilder /usr/local/bundle/ /usr/local/bundle/
COPY --from=common /shell /
COPY . .

ENV CONTAINER_NAME=tooling-invoker

ENTRYPOINT ./bin/run-local
