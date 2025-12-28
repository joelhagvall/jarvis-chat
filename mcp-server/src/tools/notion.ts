import { z } from 'zod';
import type { ToolDefinition } from '../types.js';

const NOTION_API_KEY = process.env.NOTION_API_KEY || '';
const NOTION_API_URL = 'https://api.notion.com/v1';

interface NotionObject {
  id: string;
  object: 'page' | 'database';
  properties: Record<string, unknown>;
  url: string;
  created_time: string;
  last_edited_time: string;
  title?: Array<{ plain_text: string }>;
}

interface NotionSearchResponse {
  results: NotionObject[];
  has_more: boolean;
}

interface NotionBlock {
  type: string;
  [key: string]: unknown;
}

interface NotionDatabaseRow {
  id: string;
  properties: Record<string, unknown>;
}

async function notionFetch(endpoint: string, options: RequestInit = {}): Promise<unknown> {
  const response = await fetch(`${NOTION_API_URL}${endpoint}`, {
    ...options,
    headers: {
      Authorization: `Bearer ${NOTION_API_KEY}`,
      'Notion-Version': '2022-06-28',
      'Content-Type': 'application/json',
      ...options.headers,
    },
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Notion API error: ${response.status} - ${error}`);
  }

  return response.json();
}

function extractTitle(item: NotionObject): string {
  if (item.object === 'database' && item.title?.[0]?.plain_text) {
    return item.title[0].plain_text;
  }

  const props = item.properties;
  for (const [, value] of Object.entries(props)) {
    const prop = value as { type?: string; title?: Array<{ plain_text: string }> };
    if (prop.type === 'title' && prop.title?.[0]?.plain_text) {
      return prop.title[0].plain_text;
    }
  }

  return 'Untitled';
}

function extractPropertyValue(prop: unknown): string {
  const p = prop as Record<string, unknown>;
  const type = p.type as string;

  switch (type) {
    case 'title':
    case 'rich_text': {
      const textArray = p[type] as Array<{ plain_text: string }> | undefined;
      return textArray?.map((t) => t.plain_text).join('') || '';
    }
    case 'number':
      return p.number?.toString() || '';
    case 'select': {
      const select = p.select as { name: string } | null;
      return select?.name || '';
    }
    case 'multi_select': {
      const multi = p.multi_select as Array<{ name: string }> | undefined;
      return multi?.map((s) => s.name).join(', ') || '';
    }
    case 'date': {
      const date = p.date as { start: string; end?: string } | null;
      if (!date) return '';
      return date.end ? `${date.start} → ${date.end}` : date.start;
    }
    case 'checkbox':
      return p.checkbox ? '✓' : '✗';
    case 'url':
      return (p.url as string) || '';
    case 'email':
      return (p.email as string) || '';
    case 'phone_number':
      return (p.phone_number as string) || '';
    case 'status': {
      const status = p.status as { name: string } | null;
      return status?.name || '';
    }
    case 'formula': {
      const formula = p.formula as Record<string, unknown>;
      return extractPropertyValue(formula);
    }
    default:
      return '';
  }
}

async function getDatabaseRows(databaseId: string, maxRows: number = 20): Promise<string> {
  const response = (await notionFetch(`/databases/${databaseId}/query`, {
    method: 'POST',
    body: JSON.stringify({ page_size: maxRows }),
  })) as { results: NotionDatabaseRow[] };

  if (response.results.length === 0) {
    return '(Tom databas)';
  }

  const firstRow = response.results[0];
  const columns = Object.keys(firstRow.properties);

  const rows: string[] = [];
  rows.push('| ' + columns.join(' | ') + ' |');
  rows.push('| ' + columns.map(() => '---').join(' | ') + ' |');

  for (const row of response.results) {
    const values = columns.map((col) => {
      const value = extractPropertyValue(row.properties[col]);
      return value.replace(/\|/g, '\\|').substring(0, 50) || '-';
    });
    rows.push('| ' + values.join(' | ') + ' |');
  }

  return rows.join('\n');
}

function extractBlockText(block: NotionBlock): string {
  const blockType = block.type;
  const blockData = block[blockType] as { rich_text?: Array<{ plain_text: string }> } | undefined;

  if (blockData?.rich_text) {
    return blockData.rich_text.map((t) => t.plain_text).join('');
  }

  return '';
}

async function getPageContent(pageId: string): Promise<string> {
  const response = (await notionFetch(`/blocks/${pageId}/children?page_size=100`)) as {
    results: NotionBlock[];
  };

  const textParts: string[] = [];

  for (const block of response.results) {
    const text = extractBlockText(block);
    if (text) {
      textParts.push(text);
    }
  }

  return textParts.join('\n');
}

// Cache for full-text search
let cachedPages: Array<{
  id: string;
  title: string;
  content: string;
  url: string;
  lastEdited: string;
  isDatabase: boolean;
}> | null = null;
let cacheTime = 0;
const CACHE_TTL = 5 * 60 * 1000; // 5 minutes

async function fetchAllPagesWithContent(): Promise<typeof cachedPages> {
  if (cachedPages && Date.now() - cacheTime < CACHE_TTL) {
    return cachedPages;
  }

  const pages: NonNullable<typeof cachedPages> = [];
  let hasMore = true;
  let startCursor: string | undefined;

  while (hasMore) {
    const response = (await notionFetch('/search', {
      method: 'POST',
      body: JSON.stringify({
        page_size: 100,
        start_cursor: startCursor,
      }),
    })) as NotionSearchResponse & { next_cursor?: string };

    for (const item of response.results) {
      const title = extractTitle(item);
      const isDatabase = item.object === 'database';
      let content = '';

      try {
        if (isDatabase) {
          content = await getDatabaseRows(item.id, 50);
        } else {
          content = await getPageContent(item.id);
        }
      } catch {
        content = '';
      }

      pages.push({
        id: item.id,
        title,
        content,
        url: item.url,
        lastEdited: new Date(item.last_edited_time).toLocaleDateString('sv-SE'),
        isDatabase,
      });
    }

    hasMore = response.has_more && !!response.next_cursor;
    startCursor = response.next_cursor;
  }

  cachedPages = pages;
  cacheTime = Date.now();
  return pages;
}

function searchInContent(
  pages: NonNullable<typeof cachedPages>,
  query: string,
  limit: number
): typeof pages {
  const queryLower = query.toLowerCase();
  const queryWords = queryLower.split(/\s+/).filter(w => w.length > 0);

  const scored = pages.map(page => {
    const titleLower = page.title.toLowerCase();
    const contentLower = page.content.toLowerCase();
    let score = 0;

    for (const word of queryWords) {
      if (titleLower.includes(word)) {
        score += 10;
      }
      if (contentLower.includes(word)) {
        score += 1;
        const matches = contentLower.split(word).length - 1;
        score += Math.min(matches, 5);
      }
    }

    return { page, score };
  });

  return scored
    .filter(s => s.score > 0)
    .sort((a, b) => b.score - a.score)
    .slice(0, limit)
    .map(s => s.page);
}

const notionSchema = z.object({
  query: z.string().describe('Search query to find pages containing this text (searches in titles AND content)'),
  limit: z.number().describe('Maximum number of results to return (default: 5)').optional(),
});

export const notionTool: ToolDefinition<typeof notionSchema> = {
  name: 'search_notion',
  description:
    'Search for pages and databases/tables in Notion. Searches in both titles AND page content (full-text search). Use this to find notes, documents, tables and information stored in the users Notion workspace. Returns page titles, URLs, content snippets, and full database contents as markdown tables.\n\n**Response guidelines:** When responding to the user after fetching Notion content, be constructive and reassuring – not just technical. Engage with the actual content: reflect on what the user is asking about, acknowledge the topic, and provide thoughtful feedback. If the content relates to personal projects, goals, or notes, be encouraging and supportive.',
  schema: notionSchema,
  execute: async (args) => {
    if (!NOTION_API_KEY || NOTION_API_KEY === 'din_nyckel_här') {
      return 'Notion API-nyckel saknas. Lägg till din nyckel i .env filen (NOTION_API_KEY).';
    }

    const { query, limit = 5 } = args;

    try {
      const allPages = await fetchAllPagesWithContent();

      if (!allPages || allPages.length === 0) {
        return 'Hittade inga sidor i Notion.';
      }

      const matches = searchInContent(allPages, query, limit);

      if (matches.length === 0) {
        return `Hittade inget i Notion som matchar "${query}". Sökte igenom ${allPages.length} sidor.`;
      }

      const results: string[] = [];

      for (const page of matches) {
        const typeLabel = page.isDatabase ? '📊 Databas' : '📄 Sida';
        let contentSnippet = page.content;

        const queryLower = query.toLowerCase();
        const contentLower = page.content.toLowerCase();
        const matchIndex = contentLower.indexOf(queryLower);

        if (matchIndex !== -1) {
          const start = Math.max(0, matchIndex - 100);
          const end = Math.min(page.content.length, matchIndex + query.length + 300);
          contentSnippet = (start > 0 ? '...' : '') +
            page.content.substring(start, end) +
            (end < page.content.length ? '...' : '');
        } else if (contentSnippet.length > 500) {
          contentSnippet = contentSnippet.substring(0, 500) + '...';
        }

        results.push(
          `## ${typeLabel}: ${page.title}\n` +
            `URL: ${page.url}\n` +
            `Senast redigerad: ${page.lastEdited}\n` +
            (contentSnippet ? `\n${contentSnippet}\n` : '')
        );
      }

      return `Hittade ${matches.length} resultat (sökte i ${allPages.length} sidor):\n\n` + results.join('\n---\n\n');
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      return `Fel vid sökning i Notion: ${message}`;
    }
  },
};
