package ruby_test

import (
	"fmt"

	git "gopkg.in/src-d/go-git.v4"
	"gopkg.in/src-d/go-git.v4/plumbing"
)

// Basic example of how to clone a repository using clone options.
func GitGet(directory, language, branch string) (string, error) {
	// directory, err := ioutil.TempDir("", fmt.Sprintf("%s-buildpack", language))
	// if err != nil {
	// 	return "", err
	// }

	r, err := git.PlainClone(directory, false, &git.CloneOptions{
		URL:           fmt.Sprintf("https://github.com/cloudfoundry/%s-buildpack", language),
		ReferenceName: plumbing.ReferenceName(fmt.Sprintf("refs/heads/%s", branch)),
		SingleBranch:  true,
		Depth:         1,
	})
	if err != nil {
		return "", err
	}

	ref, err := r.Head()
	if err != nil {
		return "", err
	}

	commit, err := r.CommitObject(ref.Hash())
	if err != nil {
		return "", err
	}

	return commit.String(), err
}