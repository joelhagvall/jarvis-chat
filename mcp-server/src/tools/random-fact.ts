import { z } from 'zod';
import type { ToolDefinition } from '../types.js';

const randomFactSchema = z.object({});

export const randomFactTool: ToolDefinition<typeof randomFactSchema> = {
  name: 'get_random_fact',
  description: 'Fetches a random fun fact. Use this when the user wants something fun, interesting, random facts or trivia.',
  schema: randomFactSchema,
  execute: async () => {
    try {
      const response = await fetch('https://uselessfacts.jsph.pl/api/v2/facts/random?language=en');
      if (!response.ok) {
        return 'Could not fetch fact.';
      }
      const data = (await response.json()) as { text: string };
      return data.text;
    } catch {
      return 'Could not fetch fact.';
    }
  },
};
