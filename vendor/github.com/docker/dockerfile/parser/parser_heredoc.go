//go:build dfheredoc
// +build dfheredoc

package parser

import "github.com/docker/dockerfile/parser/command"

func init() {
	heredocDirectives = map[string]bool{
		command.Add:  true,
		command.Copy: true,
		command.Run:  true,
	}

	heredocCompoundDirectives = map[string]bool{
		command.Onbuild: true,
	}
}
