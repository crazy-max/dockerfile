variable "GO_VERSION" {
  default = "1.17"
}

target "_common" {
  args = {
    GO_VERSION = GO_VERSION
    BUILDKIT_CONTEXT_KEEP_GIT_DIR = 1
  }
}

target "test" {
  inherits = ["_common"]
  target = "test-coverage"
  output = ["./coverage"]
}
