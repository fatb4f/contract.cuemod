package mcp

import (
	"bufio"
	"context"
	"encoding/json"
	"fmt"
	"io"

	acr "github.com/fatb4f/contract.cuemod/internal/contracts/agentcontextresolver"
)

type Server struct {
	Resolver acr.Resolver
}

type request struct {
	JSONRPC string          `json:"jsonrpc"`
	ID      json.RawMessage `json:"id,omitempty"`
	Method  string          `json:"method"`
	Params  json.RawMessage `json:"params,omitempty"`
}

type response struct {
	JSONRPC string          `json:"jsonrpc"`
	ID      json.RawMessage `json:"id,omitempty"`
	Result  any             `json:"result,omitempty"`
	Error   *rpcError       `json:"error,omitempty"`
}

type rpcError struct {
	Code    int    `json:"code"`
	Message string `json:"message"`
}

func (s Server) Serve(ctx context.Context, in io.Reader, out io.Writer) error {
	scanner := bufio.NewScanner(in)
	encoder := json.NewEncoder(out)
	for scanner.Scan() {
		var req request
		if err := json.Unmarshal(scanner.Bytes(), &req); err != nil {
			continue
		}
		if len(req.ID) == 0 {
			continue
		}
		res := s.handle(ctx, req)
		if err := encoder.Encode(res); err != nil {
			return err
		}
	}
	return scanner.Err()
}

func (s Server) handle(ctx context.Context, req request) response {
	result, err := s.dispatch(ctx, req)
	res := response{JSONRPC: "2.0", ID: req.ID}
	if err != nil {
		res.Error = &rpcError{Code: -32000, Message: err.Error()}
		return res
	}
	res.Result = result
	return res
}

func (s Server) dispatch(ctx context.Context, req request) (any, error) {
	switch req.Method {
	case "initialize":
		return map[string]any{
			"protocolVersion": "2024-11-05",
			"serverInfo":      map[string]string{"name": "contract-mcp", "version": "0.1.0"},
			"capabilities":    map[string]any{"tools": map[string]any{}, "resources": map[string]any{}},
		}, nil
	case "tools/list":
		return map[string]any{"tools": []map[string]any{
			{"name": "acr.inventory", "description": "Export resolver route inventory", "inputSchema": objectSchema()},
			{"name": "acr.resolve_prompt", "description": "Export resolver prompt routes", "inputSchema": objectSchema()},
			{"name": "acr.plan_route", "description": "Export resolver route plan proof", "inputSchema": objectSchema()},
			{"name": "acr.validate", "description": "Run resolver CUE validation", "inputSchema": objectSchema()},
			{"name": "acr.export_runtime_projection", "description": "Export resolver runtime projection", "inputSchema": objectSchema()},
		}}, nil
	case "tools/call":
		name, err := toolName(req.Params)
		if err != nil {
			return nil, err
		}
		data, err := s.callTool(ctx, name)
		if err != nil {
			return nil, err
		}
		return textContent(string(data)), nil
	case "resources/list":
		return map[string]any{"resources": []map[string]string{
			{"uri": "contract://agent-context-resolver/routeInventory", "name": "ACR route inventory"},
			{"uri": "contract://agent-context-resolver/runtimeProjection", "name": "ACR runtime projection"},
		}}, nil
	case "resources/read":
		uri, err := resourceURI(req.Params)
		if err != nil {
			return nil, err
		}
		data, err := s.readResource(ctx, uri)
		if err != nil {
			return nil, err
		}
		return map[string]any{"contents": []map[string]string{{"uri": uri, "mimeType": "application/json", "text": string(data)}}}, nil
	default:
		return nil, fmt.Errorf("unsupported method %s", req.Method)
	}
}

func (s Server) callTool(ctx context.Context, name string) ([]byte, error) {
	switch name {
	case "acr.inventory":
		return s.Resolver.Inventory(ctx)
	case "acr.resolve_prompt":
		return s.Resolver.ResolvePrompt(ctx, nil)
	case "acr.plan_route":
		return s.Resolver.PlanRoute(ctx, nil)
	case "acr.validate":
		data, err := s.Resolver.Validate(ctx)
		if err == nil && len(data) == 0 {
			data = []byte("ok\n")
		}
		return data, err
	case "acr.export_runtime_projection":
		return s.Resolver.ExportRuntimeProjection(ctx)
	default:
		return nil, fmt.Errorf("unknown tool %s", name)
	}
}

func (s Server) readResource(ctx context.Context, uri string) ([]byte, error) {
	switch uri {
	case "contract://agent-context-resolver/routeInventory":
		return s.Resolver.Inventory(ctx)
	case "contract://agent-context-resolver/runtimeProjection":
		return s.Resolver.ExportRuntimeProjection(ctx)
	default:
		return nil, fmt.Errorf("unknown resource %s", uri)
	}
}

func objectSchema() map[string]any {
	return map[string]any{"type": "object", "additionalProperties": true}
}

func textContent(text string) map[string]any {
	return map[string]any{"content": []map[string]string{{"type": "text", "text": text}}}
}

func toolName(raw json.RawMessage) (string, error) {
	var params struct {
		Name string `json:"name"`
	}
	if err := json.Unmarshal(raw, &params); err != nil {
		return "", err
	}
	if params.Name == "" {
		return "", fmt.Errorf("missing tool name")
	}
	return params.Name, nil
}

func resourceURI(raw json.RawMessage) (string, error) {
	var params struct {
		URI string `json:"uri"`
	}
	if err := json.Unmarshal(raw, &params); err != nil {
		return "", err
	}
	if params.URI == "" {
		return "", fmt.Errorf("missing resource uri")
	}
	return params.URI, nil
}
