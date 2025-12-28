# J.A.R.V.I.S.

A private, local AI assistant wired into my notes, tools, and workflows.

AI should be fun. Personal. Tailored. And running locally.

With open-source models and MCP servers, it's easy to build AI that lives on your machine. Not in the cloud. Not generic. This is the kind of AI I think we'll all be running soon.

## Requirements

Any machine that can run local LLMs. Apple Silicon Macs (M1-M4), Linux/Windows with a decent GPU. Modern chips like the M4 Pro handle this with ease.

## Stack

- **Client**: Native macOS app (SwiftUI)
- **Backend**: [Ollama](https://ollama.ai) running locally
- **Tools**: MCP server for system integration

## Run

```bash
swift build && swift run
```

MCP server:
```bash
cd mcp-server && bun install
```

```json
{
  "jarvis": {
    "command": "bun",
    "args": ["path/to/mcp-server/src/server.ts"]
  }
}
```
