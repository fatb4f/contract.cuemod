package cuemcp

import (
	"os/exec"
	"path/filepath"
	"testing"
)

func TestStage3ValidFixtures(t *testing.T) {
	root := filepath.Clean(filepath.Join("..", ".."))
	fixtures := []struct {
		path       string
		definition string
	}{
		{"test/fixtures/stage3/valid/projection-identity.json", "#ProjectionIdentityFixture"},
		{"test/fixtures/stage3/valid/projection-lookup.request.json", "#ProjectionLookupRequest"},
		{"test/fixtures/stage3/valid/projection-lookup.response.json", "#ProjectionLookupResponse"},
		{"test/fixtures/stage3/valid/search-policy.json", "#SearchPolicy"},
		{"test/fixtures/stage3/valid/search-request.read-only.json", "#SearchImplementationRequest"},
		{"test/fixtures/stage3/valid/search-response.read-only.json", "#SearchImplementationResponse"},
		{"test/fixtures/stage3/valid/search-response.truncated.json", "#SearchImplementationResponse"},
		{"test/fixtures/stage3/valid/search-response.model-delta.json", "#SearchImplementationResponse"},
	}

	for _, fixture := range fixtures {
		t.Run(filepath.Base(fixture.path), func(t *testing.T) {
			cmd := exec.Command("cue", "vet", ".", "-d", fixture.definition, "json:", fixture.path)
			cmd.Dir = root
			if output, err := cmd.CombinedOutput(); err != nil {
				t.Fatalf("cue vet %s: %v\n%s", fixture.definition, err, output)
			}
		})
	}
}
