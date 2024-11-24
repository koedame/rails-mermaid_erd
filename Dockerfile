FROM ruby:alpine

RUN apk add --no-cache \
      alpine-sdk \
      git \
      postgresql-dev \
      chromium \
      chromium-chromedriver \
      libc6-compat

