import type { AgentDefinition } from '../types.js';
import { dailyFactAgent } from './daily-fact.js';

// Register agents here - just add to this array to extend
export const agents: AgentDefinition[] = [
  dailyFactAgent,
];

export function getAgent(name: string): AgentDefinition | undefined {
  return agents.find((a) => a.name === name);
}

export function listAgents(): { name: string; description: string }[] {
  return agents.map((a) => ({ name: a.name, description: a.description }));
}

// Re-export types
export type { AgentDefinition, AgentStep } from '../types.js';
