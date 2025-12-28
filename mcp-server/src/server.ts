import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';
import { z } from 'zod';
import { getToolsForMcp, getTool } from './tools/index.js';

// Server configuration
const SERVER_NAME = process.env.MCP_SERVER_NAME || 'mcp-server';
const SERVER_VERSION = process.env.MCP_SERVER_VERSION || '1.0.0';

const mcpServer = new McpServer(
  {
    name: SERVER_NAME,
    version: SERVER_VERSION,
  },
  {
    capabilities: {
      tools: {},
    },
  }
);

// Use the underlying server for JSON Schema-based tools
const server = mcpServer.server;

// List all registered tools
server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: getToolsForMcp(),
}));

// Execute tool by name with Zod validation
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;
  const tool = getTool(name);

  if (!tool) {
    return { content: [{ type: 'text' as const, text: `Unknown tool: ${name}` }] };
  }

  try {
    // Validate args with Zod schema
    const validatedArgs = tool.schema.parse(args || {});
    const result = await tool.execute(validatedArgs);
    return { content: [{ type: 'text' as const, text: result }] };
  } catch (error) {
    if (error instanceof z.ZodError) {
      const issues = error.issues.map(i => `${i.path.join('.')}: ${i.message}`).join(', ');
      return { content: [{ type: 'text' as const, text: `Validation error: ${issues}` }] };
    }
    const message = error instanceof Error ? error.message : 'Unknown error';
    return { content: [{ type: 'text' as const, text: `Tool error: ${message}` }] };
  }
});

export async function startServer() {
  const transport = new StdioServerTransport();
  await mcpServer.connect(transport);
  console.error(`${SERVER_NAME} v${SERVER_VERSION} started`);
}

// Auto-start if run directly
const isMainModule = import.meta.url === `file://${process.argv[1]}`;
if (isMainModule) {
  startServer().catch(console.error);
}

// Export for programmatic use
export { mcpServer, server };
export { getToolsForMcp, getTool, registerTool } from './tools/index.js';
export { getAgent, listAgents } from './agents/index.js';
export type { ToolDefinition, AgentDefinition, AgentStep } from './types.js';
