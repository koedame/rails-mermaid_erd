FROM ruby:3.4-alpine

RUN apk add --no-cache \
      alpine-sdk \
      git \
      postgresql-dev \
      yaml-dev \
      chromium \
      chromium-chromedriver \
      libc6-compat

