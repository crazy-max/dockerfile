variable "GO_VERSION" {
  default = "1.17"
}
variable "CHANNEL" {
  default = "mainline"
}

// Special target: https://github.com/docker/metadata-action#bake-definition
target "meta-helper" {
  tags = ["dockerfile:local"]
}

target "_common" {
  args = {
    GO_VERSION = GO_VERSION
    CHANNEL = CHANNEL
    BUILDKIT_CONTEXT_KEEP_GIT_DIR = 1
  }
}

group "default" {
  targets = ["image-local"]
}

target "image" {
  inherits = ["meta-helper", "_common"]
  output = ["type=image"]
}

target "image-local" {
  inherits = ["image"]
  output = ["type=docker"]
}

target "image-cross" {
  inherits = ["image"]
  platforms = [
    "linux/amd64",
    "linux/arm/v7",
    "linux/arm64",
    "linux/ppc64le",
    "linux/riscv64",
    "linux/s390x"
  ]
}

target "vendor" {
  inherits = ["_common"]
  dockerfile = "./hack/dockerfiles/vendor.Dockerfile"
  target = "update"
  output = ["."]
}

target "mod-outdated" {
  inherits = ["_common"]
  dockerfile = "./hack/dockerfiles/vendor.Dockerfile"
  target = "outdated"
  args = {
    // used to invalidate cache for outdated run stage
    // can be dropped when https://github.com/moby/buildkit/issues/1213 fixed
    _RANDOM = uuidv4()
  }
  output = ["type=cacheonly"]
}

group "validate" {
  targets = ["lint"]
}

target "lint" {
  inherits = ["_common"]
  dockerfile = "./hack/dockerfiles/lint.Dockerfile"
  output = ["type=cacheonly"]
}

target "validate-vendor" {
  inherits = ["_common"]
  dockerfile = "./hack/dockerfiles/vendor.Dockerfile"
  target = "validate"
  output = ["type=cacheonly"]
}
