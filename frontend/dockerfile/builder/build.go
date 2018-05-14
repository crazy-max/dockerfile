package builder

import (
	"bytes"
	"context"
	"encoding/json"
	"path"
	"strings"

	"github.com/docker/docker/builder/dockerignore"
	"github.com/moby/buildkit/client/llb"
	"github.com/moby/buildkit/frontend/dockerfile/dockerfile2llb"
	"github.com/moby/buildkit/frontend/gateway/client"
	"github.com/pkg/errors"
	"golang.org/x/sync/errgroup"
)

const (
	LocalNameContext      = "context"
	LocalNameDockerfile   = "dockerfile"
	keyTarget             = "target"
	keyFilename           = "filename"
	exporterImageConfig   = "containerimage.config"
	defaultDockerfileName = "Dockerfile"
	dockerignoreFilename  = ".dockerignore"
	buildArgPrefix        = "build-arg:"
	labelPrefix           = "label:"
	gitPrefix             = "git://"
)

func Build(ctx context.Context, c client.Client) error {
	opts := c.Opts()

	filename := opts[keyFilename]
	if filename == "" {
		filename = defaultDockerfileName
	}
	if path.Base(filename) != filename {
		return errors.Errorf("invalid filename: %s", filename)
	}

	src := llb.Local(LocalNameDockerfile,
		llb.IncludePatterns([]string{filename}),
		llb.SessionID(c.SessionID()),
		llb.SharedKeyHint(defaultDockerfileName),
	)
	var buildContext *llb.State
	if strings.HasPrefix(opts[LocalNameContext], gitPrefix) {
		src = parseGitSource(opts[LocalNameContext])
		buildContext = &src
	}
	def, err := src.Marshal()
	if err != nil {
		return err
	}

	eg, ctx2 := errgroup.WithContext(ctx)
	var dtDockerfile []byte
	eg.Go(func() error {
		ref, err := c.Solve(ctx2, def.ToPB(), "", "", nil, false)
		if err != nil {
			return err
		}

		dtDockerfile, err = ref.ReadFile(ctx2, filename)
		if err != nil {
			return err
		}
		return nil
	})
	var excludes []string
	eg.Go(func() error {
		dockerignoreState := buildContext
		if dockerignoreState == nil {
			st := llb.Local(LocalNameContext,
				llb.SessionID(c.SessionID()),
				llb.IncludePatterns([]string{dockerignoreFilename}),
				llb.SharedKeyHint(dockerignoreFilename),
			)
			dockerignoreState = &st
		}
		def, err := dockerignoreState.Marshal()
		if err != nil {
			return err
		}
		ref, err := c.Solve(ctx2, def.ToPB(), "", "", nil, false)
		if err != nil {
			return err
		}
		dtDockerignore, err := ref.ReadFile(ctx2, dockerignoreFilename)
		if err == nil {
			excludes, err = dockerignore.ReadAll(bytes.NewBuffer(dtDockerignore))
			if err != nil {
				return errors.Wrap(err, "failed to parse dockerignore")
			}
		}
		return nil
	})

	if err := eg.Wait(); err != nil {
		return err
	}

	st, img, err := dockerfile2llb.Dockerfile2LLB(ctx, dtDockerfile, dockerfile2llb.ConvertOpt{
		Target:       opts[keyTarget],
		MetaResolver: c,
		BuildArgs:    filter(opts, buildArgPrefix),
		Labels:       filter(opts, labelPrefix),
		SessionID:    c.SessionID(),
		BuildContext: buildContext,
		Excludes:     excludes,
	})

	if err != nil {
		return err
	}

	def, err = st.Marshal()
	if err != nil {
		return err
	}

	config, err := json.Marshal(img)
	if err != nil {
		return err
	}

	_, err = c.Solve(ctx, def.ToPB(), "", opts["cache-from"], map[string][]byte{
		exporterImageConfig: config,
	}, true)
	if err != nil {
		return err
	}
	return nil
}

func filter(opt map[string]string, key string) map[string]string {
	m := map[string]string{}
	for k, v := range opt {
		if strings.HasPrefix(k, key) {
			m[strings.TrimPrefix(k, key)] = v
		}
	}
	return m
}

func parseGitSource(ref string) llb.State {
	ref = strings.TrimPrefix(ref, gitPrefix)
	parts := strings.SplitN(ref, "#", 2)
	branch := ""
	if len(parts) > 1 {
		branch = parts[1]
	}
	return llb.Git(parts[0], branch)
}
