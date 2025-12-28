# MCP Server

Standalone MCP (Model Context Protocol) server with tools and agents. Can be shared across different apps (Electron, SwiftUI, etc.).

## Installation

```bash
cd packages/mcp-server
npm install
npm run build
```

## Usage

### As CLI (stdio transport)

```bash
# After building
npm start

# Or directly with tsx (development)
npm run start:dev
```

### From another app

```typescript
import { spawn } from 'child_process';

// Spawn the MCP server as a subprocess
const server = spawn('node', ['path/to/mcp-server/dist/server.js'], {
  stdio: ['pipe', 'pipe', 'inherit'],
});

// Communicate via stdin/stdout using MCP protocol
```

### SwiftUI / macOS app

```swift
import Foundation

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/local/bin/node")
process.arguments = ["path/to/mcp-server/dist/server.js"]

let stdin = Pipe()
let stdout = Pipe()
process.standardInput = stdin
process.standardOutput = stdout

try process.run()

// Communicate via stdin/stdout using MCP protocol
```

## Adding New Tools

1. Create a new file in `src/tools/`:

```typescript
// src/tools/my-tool.ts
import { z } from 'zod';
import type { ToolDefinition } from '../types.js';

const mySchema = z.object({
  input: z.string().describe('Description for the LLM'),
});

export const myTool: ToolDefinition<typeof mySchema> = {
  name: 'my_tool',
  description: 'What this tool does - used by LLM to decide when to call it',
  schema: mySchema,
  execute: async (args) => {
    // Your logic here
    return `Result: ${args.input}`;
  },
};
```

2. Register in `src/tools/index.ts`:

```typescript
import { myTool } from './my-tool.js';

const rawTools: ToolDefinition[] = [
  // ... existing tools
  myTool,
];
```

3. Rebuild: `npm run build`

## Adding New Agents

Agents are multi-step workflows that combine tools:

```typescript
// src/agents/my-agent.ts
import type { AgentDefinition } from '../types.js';
import { myTool } from '../tools/my-tool.js';

export const myAgent: AgentDefinition = {
  name: 'my-agent',
  description: 'What this agent does',
  tools: [myTool],
  steps: [
    {
      id: 'step1',
      name: 'First step',
      tool: 'my_tool',
      toolArgs: { input: 'hello' },
      description: 'Running first step...',
    },
  ],
};
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `MCP_SERVER_NAME` | Custom server name (default: "mcp-server") |
| `MCP_SERVER_VERSION` | Custom version (default: "1.0.0") |
| `NOTION_API_KEY` | Notion integration token for `search_notion` tool |

## Available Tools

| Tool | Description |
|------|-------------|
| `get_notes` | Fetch/search macOS Notes app |
| `send_email_report` | Open mail client with pre-composed email |
| `get_krisinformation` | Swedish crisis alerts (Krisinformation API) |
| `get_random_fact` | Random fun facts |
| `search_notion` | Full-text search in Notion workspace |
| `get_system_info` | System stats (CPU, memory, disk, etc.) |
| `run_agent` | Execute predefined agent workflows |

## Available Agents

| Agent | Description |
|-------|-------------|
| `daily-fact` | Quick briefing with fun fact + crisis alerts |

## Project Structure

```
packages/mcp-server/
├── bin/
│   └── server.js        # CLI entry point
├── src/
│   ├── server.ts        # MCP server setup
│   ├── types.ts         # TypeScript types & Zod helpers
│   ├── tools/
│   │   ├── index.ts     # Tool registry
│   │   ├── notes.ts
│   │   ├── email.ts
│   │   └── ...
│   └── agents/
│       ├── index.ts     # Agent registry
│       └── daily-fact.ts
├── package.json
└── tsconfig.json
```
