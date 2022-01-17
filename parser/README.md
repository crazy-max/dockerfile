<!-- FIXME: Uncomment when moved to docker org
[![PkgGoDev](https://img.shields.io/badge/go.dev-docs-007d9c?logo=go&logoColor=white)](https://pkg.go.dev/github.com/docker/dockerfile/parser)
[![Test Status](https://img.shields.io/github/workflow/status/docker/dockerfile/parser?label=test&logo=github&style=flat-square)](https://github.com/docker/dockerfile/actions?query=workflow%3Aparser)
-->

## About

This directory contains the parser and tree dumper for Dockerfiles.

## Test

```shell
$ docker buildx bake test
```

## Usage

```shell
go get github.com/docker/dockerfile/parser
```

```go
package main

import (
	"bytes"
	"os"

	"github.com/docker/dockerfile/parser"
)

func main() {
	b, err := os.ReadFile("Dockerfile")
	if err != nil {
		panic(err)
	}

	_, err = parser.Parse(bytes.NewReader(b))
	if err != nil {
		panic(err)
	}
}
```
