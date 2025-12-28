import { z } from 'zod';
import type { ToolDefinition } from '../types.js';

interface KrisItem {
  Headline?: string;
  Preamble?: string;
  Published?: string;
  Updated?: string;
  Area?: Array<{ Description?: string }>;
}

const krisinformationSchema = z.object({
  type: z.enum(['news', 'vmas', 'notifications', 'topstories']).describe('Type of info: news (crisis news), vmas (VMA alerts), notifications (push notifications), topstories (major events)'),
});

export const krisinformationTool: ToolDefinition<typeof krisinformationSchema> = {
  name: 'get_krisinformation',
  description: 'Fetches crisis information from the Swedish Krisinformation API. Use this when the user asks about emergencies, alerts, VMA, or crisis news in Sweden.',
  schema: krisinformationSchema,
  execute: async (args) => {
    const { type } = args;

    const endpoints: Record<string, string> = {
      news: 'https://api.krisinformation.se/v3/news',
      vmas: 'https://api.krisinformation.se/v3/vmas',
      notifications: 'https://api.krisinformation.se/v3/notifications',
      topstories: 'https://api.krisinformation.se/v3/topstories',
    };

    const url = endpoints[type];
    if (!url) {
      throw new Error(`Unknown krisinformation type: ${type}`);
    }

    const response = await fetch(url);
    if (!response.ok) {
      throw new Error(`API request failed: ${response.status}`);
    }

    const data = (await response.json()) as KrisItem[];

    if (!Array.isArray(data) || data.length === 0) {
      return `Inga ${type} just nu.`;
    }

    const items = data.slice(0, 5).map((item) => {
      const headline = item.Headline || 'Ingen rubrik';
      const preamble = item.Preamble || '';
      const area = item.Area?.[0]?.Description || '';
      const date = item.Published || item.Updated || '';
      return `- ${headline}${area ? ` (${area})` : ''}${date ? ` [${date}]` : ''}\n  ${preamble}`;
    });

    return items.join('\n\n');
  },
};
