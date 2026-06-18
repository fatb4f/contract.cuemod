package assertions

import (
	agentruntime "github.com/fatb4f/contract.cuemod/contracts/agent-runtime:agentruntime"
	rootadapters "github.com/fatb4f/contract.cuemod/contracts/adapters:adapters"
	contextpacket "github.com/fatb4f/contract.cuemod/contracts/context/packet:resolver"
	a2a "github.com/fatb4f/contract.cuemod/contracts/protocols/a2a:a2a"
	mcp "github.com/fatb4f/contract.cuemod/contracts/protocols/mcp:mcp"
)

rootExtractability: {
	"protocols/mcp": mcp.domain & {
		authority:   true
		extractable: true
	}
	"protocols/a2a": a2a.domain & {
		authority:   true
		extractable: true
	}
	"context/packet": contextpacket.domain & {
		authority:   true
		extractable: true
	}
	adapters: rootadapters.domain & {
		authority:   true
		extractable: true
	}
	"agent-runtime": agentruntime.domain & {
		authority:   true
		extractable: true
	}
}
