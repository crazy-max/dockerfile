# BuildKit Dockerfile frontend

<!-- FIXME: Remove comment when moved to docker org
[![PkgGoDev](https://img.shields.io/badge/go.dev-docs-007d9c?logo=go&logoColor=white)](https://pkg.go.dev/github.com/docker/dockerfile)
[![GitHub release](https://img.shields.io/github/release/docker/dockerfile.svg?style=flat-square)](https://github.com/docker/dockerfile/releases/latest)
[![Build Status](https://img.shields.io/github/workflow/status/docker/dockerfile/build?label=build&logo=github&style=flat-square)](https://github.com/docker/dockerfile/actions?query=workflow%3Abuild)
[![Docker Stars](https://img.shields.io/docker/stars/docker/dockerfile.svg?style=flat-square&logo=docker)](https://hub.docker.com/r/docker/dockerfile/)
[![Docker Pulls](https://img.shields.io/docker/pulls/docker/dockerfile.svg?style=flat-square&logo=docker)](https://hub.docker.com/r/docker/dockerfile/)

[![Go Report Card](https://goreportcard.com/badge/github.com/docker/dockerfile?style=flat-square)](https://goreportcard.com/report/github.com/docker/dockerfile)
[![codecov](https://img.shields.io/codecov/c/github/docker/dockerfile?logo=codecov&style=flat-square)](https://codecov.io/gh/docker/dockerfile)
-->

Official Dockerfile frontend that enables building Dockerfiles with [BuildKit](https://github.com/moby/buildkit).

___

- [Note for Docker users](#note-for-docker-users)
- [Using external Dockerfile frontend](#using-external-dockerfile-frontend)
- [Build](#build)
- [Examples](#examples)
- [Syntax](#syntax)
  - [Build Mounts `RUN --mount=...`](#build-mounts-run---mount)
    - [`RUN --mount=type=bind` (the default mount type)](#run---mounttypebind-the-default-mount-type)
    - [`RUN --mount=type=cache`](#run---mounttypecache)
      - [Example: cache Go packages](#example-cache-go-packages)
      - [Example: cache apt packages](#example-cache-apt-packages)
    - [`RUN --mount=type=tmpfs`](#run---mounttypetmpfs)
    - [`RUN --mount=type=secret`](#run---mounttypesecret)
      - [Example: access to S3](#example-access-to-s3)
    - [`RUN --mount=type=ssh`](#run---mounttypessh)
      - [Example: access to Gitlab](#example-access-to-gitlab)
    - [`RUN --network=none|host|default` (network modes)](#run---networknonehostdefault-network-modes)
      - [Example: isolating external effects](#example-isolating-external-effects)
    - [`RUN --security=insecure|sandbox` (security context)](#run---securityinsecuresandbox-security-context)
      - [Example: check entitlements](#example-check-entitlements)
  - [Here-Documents](#here-documents)
  - [Built-in build args](#built-in-build-args)
- [Contributing](#contributing)

## Note for Docker users

If you are using Docker v18.09 or later, BuildKit mode can be enabled by setting `export DOCKER_BUILDKIT=1` on the client side.

[Docker Buildx](https://github.com/docker/buildx) always enables BuildKit.

## Using external Dockerfile frontend

BuildKit supports loading frontends dynamically from container images. Images for Dockerfile frontends are available at [`docker/dockerfile`](https://hub.docker.com/r/docker/dockerfile/tags/) repository.

To use the external frontend, the first line of your Dockerfile needs to be `# syntax=docker/dockerfile:1.3` pointing to the
specific image you want to use.

BuildKit also ships with Dockerfile frontend builtin but it is recommended to use an external image to make sure that all
users use the same version on the builder and to pick up bugfixes automatically without waiting for a new version of BuildKit
or Docker engine.

The images are published on two channels: *latest* and *labs*. The latest channel uses semver versioning while labs uses an
[incrementing number](https://github.com/moby/buildkit/issues/528). This means the labs channel may remove a feature without
incrementing the major component of a version and you may want to pin the image to a specific revision. Even when syntaxes
change in between releases on labs channel, the old versions are guaranteed to be backward compatible.

## Build

`docker/dockerfile` is developed using Docker.

```shell
# build mainline channel image (output to docker)
make image

# build mainline channel image (output to docker)
CHANNEL=labs make image

# vendor
make vendor

# validate
make validate

# check dependencies updates
make mod-outdated

# build and push multi-platform mainline channel image to username/dockerfile:test
docker buildx bake image-cross --push --set *.tags=username/dockerfile:test
```

## Examples

### CLI examples

* [`build-using-dockerfile`](./examples/build-using-dockerfile): a BuildKit client with `docker build`-style CLI

### LLB examples

* [`dockerfile2llb`](./examples/dockerfile2llb): convert a Dockerfile to LLB for debugging purposes

## Syntax

### Build Mounts `RUN --mount=...`

To use this flag set Dockerfile version to at least `1.2`

```dockerfile
# syntax=docker/dockerfile:1.3
```

`RUN --mount` allows you to create mounts that process running as part of the build can access. This can be used to bind
files from other part of the build without copying, accessing build secrets or ssh-agent sockets, or creating cache
locations to speed up your build.

#### `RUN --mount=type=bind` (the default mount type)

This mount type allows binding directories (read-only) in the context or in an image to the build container.

|Option               |Description|
|---------------------|-----------|
|`target` (required)  | Mount path.|
|`source`             | Source path in the `from`. Defaults to the root of the `from`.|
|`from`               | Build stage or image name for the root of the source. Defaults to the build context.|
|`rw`,`readwrite`     | Allow writes on the mount. Written data will be discarded.|

#### `RUN --mount=type=cache`

This mount type allows the build container to cache directories for compilers and package managers.

|Option               |Description|
|---------------------|-----------|
|`id`                 | Optional ID to identify separate/different caches. Defaults to value of `target`. |
|`target` (required)  | Mount path.|
|`ro`,`readonly`      | Read-only if set.|
|`sharing`            | One of `shared`, `private`, or `locked`. Defaults to `shared`. A `shared` cache mount can be used concurrently by multiple writers. `private` creates a new mount if there are multiple writers. `locked` pauses the second writer until the first one releases the mount.|
|`from`               | Build stage to use as a base of the cache mount. Defaults to empty directory.|
|`source`             | Subpath in the `from` to mount. Defaults to the root of the `from`.|
|`mode`               | File mode for new cache directory in octal. Default 0755.|
|`uid`                | User ID for new cache directory. Default 0.|
|`gid`                | Group ID for new cache directory. Default 0.|

Contents of the cache directories persists between builder invocations without invalidating the
instruction cache. Cache mounts should only be used for better performance. Your build should work
with any contents of the cache directory as another build may overwrite the files or GC may clean
it if more storage space is needed.

##### Example: cache Go packages

```dockerfile
# syntax = docker/dockerfile:1.3
FROM golang
...
RUN --mount=type=cache,target=/root/.cache/go-build go build ...
```

##### Example: cache apt packages

```dockerfile
# syntax = docker/dockerfile:1.3
FROM ubuntu
RUN rm -f /etc/apt/apt.conf.d/docker-clean; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache
RUN --mount=type=cache,target=/var/cache/apt --mount=type=cache,target=/var/lib/apt \
  apt update && apt-get --no-install-recommends install -y gcc
```

#### `RUN --mount=type=tmpfs`

This mount type allows mounting tmpfs in the build container.

|Option               |Description|
|---------------------|-----------|
|`target` (required)  | Mount path.|
|`size`               | Specify an upper limit on the size of the filesystem.|

#### `RUN --mount=type=secret`

This mount type allows the build container to access secure files such as private keys without baking them into the image.

|Option               |Description|
|---------------------|-----------|
|`id`                 | ID of the secret. Defaults to basename of the target path.|
|`target`             | Mount path. Defaults to `/run/secrets/` + `id`.|
|`required`           | If set to `true`, the instruction errors out when the secret is unavailable. Defaults to `false`.|
|`mode`               | File mode for secret file in octal. Default 0400.|
|`uid`                | User ID for secret file. Default 0.|
|`gid`                | Group ID for secret file. Default 0.|

##### Example: access to S3

```dockerfile
# syntax = docker/dockerfile:1.3
FROM python:3
RUN pip install awscli
RUN --mount=type=secret,id=aws,target=/root/.aws/credentials aws s3 cp s3://... ...
```

```console
$ docker build --secret id=aws,src=$HOME/.aws/credentials .
```

```console
$ buildctl build --frontend=dockerfile.v0 --local context=. --local dockerfile=. \
  --secret id=aws,src=$HOME/.aws/credentials
```

#### `RUN --mount=type=ssh`

This mount type allows the build container to access SSH keys via SSH agents, with support for passphrases.

|Option               |Description|
|---------------------|-----------|
|`id`                 | ID of SSH agent socket or key. Defaults to "default".|
|`target`             | SSH agent socket path. Defaults to `/run/buildkit/ssh_agent.${N}`.|
|`required`           | If set to `true`, the instruction errors out when the key is unavailable. Defaults to `false`.|
|`mode`               | File mode for socket in octal. Default 0600.|
|`uid`                | User ID for socket. Default 0.|
|`gid`                | Group ID for socket. Default 0.|

##### Example: access to Gitlab

```dockerfile
# syntax = docker/dockerfile:1.3
FROM alpine
RUN apk add --no-cache openssh-client
RUN mkdir -p -m 0700 ~/.ssh && ssh-keyscan gitlab.com >> ~/.ssh/known_hosts
RUN --mount=type=ssh ssh -q -T git@gitlab.com 2>&1 | tee /hello
# "Welcome to GitLab, @GITLAB_USERNAME_ASSOCIATED_WITH_SSHKEY" should be printed here
# with the type of build progress is defined as `plain`.
```

```console
$ eval $(ssh-agent)
$ ssh-add ~/.ssh/id_rsa
(Input your passphrase here)
$ docker build --ssh default=$SSH_AUTH_SOCK .
```

```
$ buildctl build --frontend=dockerfile.v0 --local context=. --local dockerfile=. \
  --ssh default=$SSH_AUTH_SOCK
```

You can also specify a path to `*.pem` file on the host directly instead of `$SSH_AUTH_SOCK`.
However, pem files with passphrases are not supported.

#### `RUN --network=none|host|default` (network modes)

```
# syntax=docker/dockerfile:1.3
```

`RUN --network` allows control over which networking environment the command is run in.

The allowed values are:

* `none` - The command is run with no network access (`lo` is still available,
    but is isolated to this process)
* `host` - The command is run in the host's network environment (similar to
    `docker build --network=host`, but on a per-instruction basis)
* `default` - Equivalent to not supplying a flag at all, the command is run in
    the default network for the build

The use of `--network=host` is protected by the `network.host` entitlement,
which needs to be enabled when starting the buildkitd daemon
(`--allow-insecure-entitlement network.host`) and on the build request
(`--allow network.host`).

##### Example: isolating external effects

```dockerfile
# syntax = docker/dockerfile:1.3
FROM python:3.6
ADD mypackage.tgz wheels/
RUN --network=none pip install --find-links wheels mypackage
```

`pip` will only be able to install the packages provided in the tarfile, which
can be controlled by an earlier build stage.

#### `RUN --security=insecure|sandbox` (security context)

To use this flag, set Dockerfile version to `labs` channel.

```
# syntax=docker/dockerfile:1.3-labs
```

With `--security=insecure`, builder runs the command without sandbox in insecure mode,
which allows to run flows requiring elevated privileges (e.g. containerd). This is equivalent
to running `docker run --privileged`. In order to access this feature, entitlement
`security.insecure` should be enabled when starting the buildkitd daemon
(`--allow-insecure-entitlement security.insecure`) and for a build request
(`--allow security.insecure`).

Default sandbox mode can be activated via `--security=sandbox`, but that is no-op.

##### Example: check entitlements

```dockerfile
# syntax = docker/dockerfile:1.3-labs
FROM ubuntu
RUN --security=insecure cat /proc/self/status | grep CapEff
```

```
#84 0.093 CapEff:	0000003fffffffff
```

### Here-Documents

To use this flag, set Dockerfile version to `labs` channel. This feature is available
since `docker/dockerfile:1.3.0-labs` release.

```
# syntax=docker/dockerfile:1.3-labs
```

Here-documents allow redirection of subsequent Dockerfile lines to the input of `RUN` or `COPY` commands.
If such command contains a [here-document](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_07_04)
Dockerfile will consider the next lines until the line only containing a here-doc delimiter as part of the same command.

#### Example: running a multi-line script

```dockerfile
# syntax = docker/dockerfile:1.3-labs
FROM debian
RUN <<eot bash
  apt-get update
  apt-get install -y vim
eot
```

If the command only contains a here-document, its contents is evaluated with the default shell.

```dockerfile
# syntax = docker/dockerfile:1.3-labs
FROM debian
RUN <<eot
  mkdir -p foo/bar
eot
```

Alternatively, shebang header can be used to define an interpreter.

```dockerfile
# syntax = docker/dockerfile:1.3-labs
FROM python:3.6
RUN <<eot
#!/usr/bin/env python
print("hello world")
eot
```

More complex examples may use multiple here-documents.

```dockerfile
# syntax = docker/dockerfile:1.3-labs
FROM alpine
RUN <<FILE1 cat > file1 && <<FILE2 cat > file2
I am
first
FILE1
I am
second
FILE2
```

#### Example: creating inline files

In `COPY` commands source parameters can be replaced with here-doc indicators.
Regular here-doc [variable expansion and tab stripping rules](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_07_04) apply.

```dockerfile
# syntax = docker/dockerfile:1.3-labs
FROM alpine
ARG FOO=bar
COPY <<-eot /app/foo
	hello ${FOO}
eot
```

```dockerfile
# syntax = docker/dockerfile:1.3-labs
FROM alpine
COPY <<-"eot" /app/script.sh
	echo hello ${FOO}
eot
RUN FOO=abc ash /app/script.sh
```

### Built-in build args

* `BUILDKIT_CACHE_MOUNT_NS=<string>` set optional cache ID namespace
* `BUILDKIT_CONTEXT_KEEP_GIT_DIR=<bool>` trigger git context to keep the `.git` directory
* `BUILDKIT_INLINE_CACHE=<bool>` inline cache metadata to image configuration or not (for Docker-integrated BuildKit (`DOCKER_BUILDKIT=1 docker build`) and `docker buildx`)
* `BUILDKIT_MULTI_PLATFORM=<bool>` opt into determnistic output regardless of multi-platform output or not
* `BUILDKIT_SANDBOX_HOSTNAME=<string>` set the hostname (default `buildkitsandbox`)
* `BUILDKIT_SYNTAX=<image>` set frontend image

## Contributing

Want to contribute? Awesome! You can find information about contributing
to this project in the [CONTRIBUTING.md](/.github/CONTRIBUTING.md)
