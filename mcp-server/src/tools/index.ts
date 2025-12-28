import { type ToolDefinition, GLOBAL_TOOL_RULES, zodToJsonSchema } from '../types.js';
import { notesTool } from './notes.js';
import { krisinformationTool } from './krisinformation.js';
import { emailTool } from './email.js';
import { randomFactTool } from './random-fact.js';
import { notionTool } from './notion.js';
import { systemInfoTool } from './system-info.js';
import { runAgentTool } from './run-agent.js';

// ============================================
// TOOL REGISTRY
// ============================================
// To add a new tool:
// 1. Create a new file in this directory (e.g., my-tool.ts)
// 2. Export a ToolDefinition from that file
// 3. Import and add it to the rawTools array below
// ============================================

// eslint-disable-next-line @typescript-eslint/no-explicit-any
const rawTools: ToolDefinition<any>[] = [
  notesTool,
  krisinformationTool,
  emailTool,
  randomFactTool,
  notionTool,
  systemInfoTool,
  runAgentTool,
];

// Apply global rules to all tool descriptions
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const tools: ToolDefinition<any>[] = rawTools.map((tool) => ({
  ...tool,
  description: `${tool.description} ${GLOBAL_TOOL_RULES}`,
}));

// Helper to get tool by name
export function getTool(name: string): ToolDefinition | undefined {
  return tools.find((t) => t.name === name);
}

// Register a new tool at runtime
export function registerTool(tool: ToolDefinition): void {
  const existingIndex = rawTools.findIndex(t => t.name === tool.name);
  if (existingIndex >= 0) {
    rawTools[existingIndex] = tool;
  } else {
    rawTools.push(tool);
  }
  // Update the exported tools array
  tools.length = 0;
  tools.push(...rawTools.map((t) => ({
    ...t,
    description: `${t.description} ${GLOBAL_TOOL_RULES}`,
  })));
}

// Get JSON Schema representation for MCP protocol
export function getToolsForMcp(): Array<{
  name: string;
  description: string;
  inputSchema: { type: 'object'; properties: Record<string, unknown>; required: string[] };
}> {
  return tools.map((tool) => ({
    name: tool.name,
    description: tool.description,
    inputSchema: zodToJsonSchema(tool.schema),
  }));
}

// Re-export for convenience
export type { ToolDefinition } from '../types.js';
export { zodToJsonSchema } from '../types.js';
