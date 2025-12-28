import { z } from 'zod';
import type { ToolDefinition } from '../types.js';
import { getAgent, listAgents } from '../agents/index.js';

// Import tools directly to avoid circular dependency
import { randomFactTool } from './random-fact.js';
import { krisinformationTool } from './krisinformation.js';
import { notesTool } from './notes.js';
import { emailTool } from './email.js';
import { notionTool } from './notion.js';
import { systemInfoTool } from './system-info.js';

// eslint-disable-next-line @typescript-eslint/no-explicit-any
const toolRegistry: Record<string, ToolDefinition<any>> = {
  get_random_fact: randomFactTool,
  get_krisinformation: krisinformationTool,
  get_notes: notesTool,
  send_email_report: emailTool,
  search_notion: notionTool,
  get_system_info: systemInfoTool,
};

const runAgentSchema = z.object({
  agent: z.string().describe('Name of the agent to run'),
});

export const runAgentTool: ToolDefinition<typeof runAgentSchema> = {
  name: 'run_agent',
  description: 'Run a predefined agent workflow. Use this when the user asks to run an agent, daily briefing, or wants a structured multi-step workflow. Available agents: "daily-fact" (quick briefing with fun fact and crisis alerts).',
  schema: runAgentSchema,
  execute: async (args) => {
    const { agent: agentName } = args;
    const agent = getAgent(agentName);

    if (!agent) {
      const available = listAgents().map(a => a.name).join(', ');
      return `Unknown agent: "${agentName}". Available agents: ${available}`;
    }

    const results: string[] = [];
    results.push(`# ${agent.name}`);
    results.push(`${agent.description}\n`);

    if (!agent.steps || agent.steps.length === 0) {
      return `Agent "${agentName}" has no steps defined.`;
    }

    // Execute each step
    for (let i = 0; i < agent.steps.length; i++) {
      const step = agent.steps[i];
      results.push(`## Step ${i + 1}: ${step.name}`);

      if (step.tool) {
        const tool = toolRegistry[step.tool];
        if (tool) {
          try {
            // Parse args through the tool's schema before executing
            const validatedArgs = tool.schema.parse(step.toolArgs || {});
            const toolResult = await tool.execute(validatedArgs);
            results.push(toolResult);
            results.push('');
          } catch (error) {
            results.push(`Error: ${error instanceof Error ? error.message : 'Unknown error'}`);
            results.push('');
          }
        } else {
          results.push(`Error: Tool "${step.tool}" not found`);
          results.push('');
        }
      } else {
        results.push(`${step.description}`);
        results.push('');
      }
    }

    return results.join('\n');
  },
};
