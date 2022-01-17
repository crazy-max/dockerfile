# syntax=docker/dockerfile:1-labs

ARG GO_VERSION=1.17

FROM --platform=$BUILDPLATFORM golang:${GO_VERSION}-alpine AS base
RUN apk add --no-cache file git
ENV CGO_ENABLED=0
ENV GOFLAGS=-mod=mod
WORKDIR /src

FROM base AS test
RUN --mount=type=bind,target=. \
  --mount=type=cache,target=/root/.cache \
  --mount=type=cache,target=/go/pkg/mod \
  go test -v -coverprofile=/tmp/coverage.txt -covermode=atomic ./... && \
  go tool cover -func=/tmp/coverage.txt

FROM scratch AS test-coverage
COPY --from=test /tmp/coverage.txt /coverage.txt
