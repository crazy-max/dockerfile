# syntax=docker/dockerfile:1-labs

ARG GO_VERSION=1.17
ARG XX_VERSION=1.1.0
ARG CHANNEL

# xx is a helper for cross-compilation
FROM --platform=$BUILDPLATFORM tonistiigi/xx:${XX_VERSION} AS xx

FROM --platform=$BUILDPLATFORM golang:${GO_VERSION}-alpine AS base
COPY --from=xx / /
RUN apk add --no-cache file git
ENV CGO_ENABLED=0
ENV GOFLAGS=-mod=vendor
WORKDIR /src

FROM base AS version
ARG CHANNEL
RUN --mount=target=. <<EOT
channel=$CHANNEL
suffix=""
buildtags=""
if [ -z "$channel" ]; then
  channel="mainline"
fi
if [ "$channel" != "mainline" ]; then
  suffix="-$channel"
fi
if [ -f "./release/$channel/tags" ]; then
  buildtags="$(cat ./release/$channel/tags)"
fi
PKG=github.com/docker/dockerfile
VERSION=$(git describe --match 'v[0-9]*' --dirty='.m' --always --tags)$suffix
REVISION=$(git rev-parse HEAD)$(if ! git diff --no-ext-diff --quiet --exit-code; then echo .m; fi)
echo "-X main.Version=${VERSION} -X main.Revision=${REVISION} -X main.Package=${PKG}" | tee /tmp/.ldflags
echo -n "${VERSION}" | tee /tmp/.version
echo -n "${buildtags}" | tee /tmp/.buildtags
EOT

FROM base AS build
ARG LDFLAGS="-w -s"
ARG TARGETPLATFORM
RUN --mount=type=bind,target=. \
  --mount=type=cache,target=/root/.cache \
  --mount=type=cache,target=/go/pkg/mod \
  --mount=type=bind,from=version,source=/tmp/.ldflags,target=/tmp/.ldflags \
  --mount=type=bind,from=version,source=/tmp/.buildtags,target=/tmp/.buildtags <<EOT
(set -x ; xx-go build -o /dockerfile-frontend -ldflags "-d $(cat /tmp/.ldflags) ${LDFLAGS}" -tags "$(cat /tmp/.buildtags) netgo static_build osusergo" ./cmd/dockerfile-frontend)
xx-verify --static /dockerfile-frontend
EOT

FROM scratch
LABEL moby.buildkit.frontend.network.none="true"
LABEL moby.buildkit.frontend.caps="moby.buildkit.frontend.inputs,moby.buildkit.frontend.subrequests,moby.buildkit.frontend.contexts"
COPY --from=build /dockerfile-frontend /bin/dockerfile-frontend
ENTRYPOINT ["/bin/dockerfile-frontend"]
