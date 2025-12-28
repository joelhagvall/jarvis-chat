import type { AgentDefinition } from '../types.js';
import { randomFactTool } from '../tools/random-fact.js';
import { krisinformationTool } from '../tools/krisinformation.js';

export const dailyFactAgent: AgentDefinition = {
  name: 'daily-fact',
  description: 'Get a quick daily briefing with a fun fact and any crisis alerts',
  systemPrompt: `You are the Daily Fact Agent. Your job is to give the user a quick, cheerful daily briefing.

Follow these steps IN ORDER. Wait for each tool result before proceeding:

## Step 1: Fun Fact
- Call get_random_fact to fetch a fun fact
- Present it in an engaging way

## Step 2: Safety Check
- Call get_krisinformation with type "vmas" to check for VMA alerts
- If there are alerts: summarize them clearly with a ⚠️ warning
- If no alerts: say "No active alerts - all clear! ✓"

## Step 3: Wrap Up
- End with a short, friendly closing message
- Format the whole response nicely with sections

Keep it brief and positive!`,
  tools: [randomFactTool, krisinformationTool],
  steps: [
    {
      id: 'fact',
      name: 'Get fun fact',
      tool: 'get_random_fact',
      description: 'Fetching a random fun fact...',
    },
    {
      id: 'crisis',
      name: 'Check alerts',
      tool: 'get_krisinformation',
      toolArgs: { type: 'vmas' },
      description: 'Checking for crisis alerts...',
    },
    {
      id: 'summary',
      name: 'Present summary',
      description: 'Presenting your daily briefing',
      requiresUserAction: false,
    },
  ],
};
