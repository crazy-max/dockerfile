module github.com/docker/dockerfile/parser

go 1.17

require (
	github.com/docker/docker v20.10.12+incompatible // master
	github.com/google/go-cmp v0.5.6
	github.com/moby/buildkit v0.9.3
	github.com/pkg/errors v0.9.1
	github.com/stretchr/testify v1.7.0
)

require (
	github.com/agext/levenshtein v1.2.3 // indirect
	github.com/containerd/typeurl v1.0.2 // indirect
	github.com/davecgh/go-spew v1.1.1 // indirect
	github.com/docker/go-connections v0.4.0 // indirect
	github.com/docker/go-units v0.4.0 // indirect
	github.com/gogo/protobuf v1.3.2 // indirect
	github.com/golang/protobuf v1.5.2 // indirect
	github.com/kr/text v0.2.0 // indirect
	github.com/opencontainers/go-digest v1.0.0 // indirect
	github.com/opencontainers/image-spec v1.0.2-0.20210819154149-5ad6f50d6283 // indirect
	github.com/pmezard/go-difflib v1.0.0 // indirect
	google.golang.org/protobuf v1.27.1 // indirect
	gopkg.in/check.v1 v1.0.0-20201130134442-10cb98267c6c // indirect
	gopkg.in/yaml.v3 v3.0.0-20210107192922-496545a6307b // indirect
)

replace (
	github.com/docker/docker => github.com/docker/docker v20.10.3-0.20211208011758-87521affb077+incompatible
	// FIXME: Use github.com/moby/buildkit
	github.com/moby/buildkit => github.com/crazy-max/buildkit-nofrontend v0.0.0-20220117003734-6471f316d3e6
)
