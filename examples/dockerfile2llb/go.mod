module github.com/docker/dockerfile/examples/dockerfile2llb

go 1.17

require (
	github.com/docker/dockerfile v0.0.0-00010101000000-000000000000
	github.com/moby/buildkit v0.9.1-0.20220107201744-ffe2301031c8
)

require (
	github.com/agext/levenshtein v1.2.3 // indirect
	github.com/containerd/containerd v1.6.0-beta.3 // indirect
	github.com/containerd/ttrpc v1.1.0 // indirect
	github.com/containerd/typeurl v1.0.2 // indirect
	github.com/docker/distribution v2.7.1+incompatible // indirect
	github.com/docker/docker v20.10.7+incompatible // indirect
	github.com/docker/go-connections v0.4.0 // indirect
	github.com/docker/go-units v0.4.0 // indirect
	github.com/gogo/protobuf v1.3.2 // indirect
	github.com/golang/protobuf v1.5.2 // indirect
	github.com/google/shlex v0.0.0-20191202100458-e7afc7fbc510 // indirect
	github.com/klauspost/compress v1.13.6 // indirect
	github.com/moby/locker v1.0.1 // indirect
	github.com/moby/sys/signal v0.6.0 // indirect
	github.com/opencontainers/go-digest v1.0.0 // indirect
	github.com/opencontainers/image-spec v1.0.2-0.20210819154149-5ad6f50d6283 // indirect
	github.com/pkg/errors v0.9.1 // indirect
	github.com/sirupsen/logrus v1.8.1 // indirect
	golang.org/x/crypto v0.0.0-20211202192323-5770296d904e // indirect
	golang.org/x/net v0.0.0-20211123203042-d83791d6bcd9 // indirect
	golang.org/x/sync v0.0.0-20210220032951-036812b2e83c // indirect
	golang.org/x/sys v0.0.0-20211123173158-ef496fb156ab // indirect
	google.golang.org/genproto v0.0.0-20211118181313-81c1377c94b1 // indirect
	google.golang.org/grpc v1.42.0 // indirect
	google.golang.org/protobuf v1.27.1 // indirect
)

replace (
	github.com/docker/docker => github.com/docker/docker v20.10.3-0.20211208011758-87521affb077+incompatible
	github.com/docker/dockerfile => ../../
)
