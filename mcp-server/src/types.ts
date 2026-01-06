import { z } from 'zod';

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export interface ToolDefinition<TSchema extends z.ZodType<any, any, any> = z.ZodType<any, any, any>> {
  name: string;
  description: string;
  schema: TSchema;
  execute: (args: z.infer<TSchema>) => Promise<string>;
}

// Step definition for multi-step agents
export interface AgentStep {
  id: string;
  name: string;
  description: string;
  tool?: string;
  toolArgs?: Record<string, unknown>;
  requiresUserAction?: boolean;
}

// Agent definition - an agent is a collection of tools with shared context
export interface AgentDefinition {
  name: string;
  description: string;
  systemPrompt?: string;
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  tools: ToolDefinition<any>[];
  steps?: AgentStep[];
}

// Helper to get Zod type (works with Zod v3 and v4)
function getZodType(schema: z.ZodType): string {
  // Zod stores type in _def.typeName
  const def = (schema as unknown as { _def?: { typeName?: string } })._def;
  const typeName = def?.typeName ?? '';
  // Convert ZodObject -> object, ZodString -> string, etc.
  return typeName.replace('Zod', '').toLowerCase();
}

// Helper to convert Zod schema to JSON Schema for MCP protocol
export function zodToJsonSchema(schema: z.ZodType): {
  type: 'object';
  properties: Record<string, unknown>;
  required: string[];
} {
  const typeName = getZodType(schema);

  if (typeName === 'object') {
    const shape = (schema as z.ZodObject<z.ZodRawShape>).shape;
    const properties: Record<string, unknown> = {};
    const required: string[] = [];

    for (const [key, value] of Object.entries(shape)) {
      const zodValue = value as z.ZodType;
      properties[key] = zodTypeToJsonSchema(zodValue);
      if (!isOptional(zodValue)) {
        required.push(key);
      }
    }

    return { type: 'object', properties, required };
  }

  return { type: 'object', properties: {}, required: [] };
}

function isOptional(schema: z.ZodType): boolean {
  const typeName = getZodType(schema);
  return typeName === 'optional' || typeName === 'default';
}

function unwrapSchema(schema: z.ZodType): z.ZodType {
  const typeName = getZodType(schema);
  if (typeName === 'optional') {
    return (schema as z.ZodOptional<z.ZodType>).unwrap();
  }
  if (typeName === 'default') {
    return (schema as z.ZodDefault<z.ZodType>).removeDefault();
  }
  return schema;
}

function zodTypeToJsonSchema(schema: z.ZodType): Record<string, unknown> {
  // Capture description BEFORE unwrapping (it's on the outer optional/default wrapper)
  const outerDescription = schema.description;
  const innerSchema = unwrapSchema(schema);
  const typeName = getZodType(innerSchema);
  // Use outer description if available, otherwise inner
  const description = outerDescription ?? innerSchema.description;

  if (typeName === 'string') {
    const result: Record<string, unknown> = { type: 'string' };
    if (description) result.description = description;
    return result;
  }

  if (typeName === 'number') {
    const result: Record<string, unknown> = { type: 'number' };
    if (description) result.description = description;
    return result;
  }

  if (typeName === 'boolean') {
    const result: Record<string, unknown> = { type: 'boolean' };
    if (description) result.description = description;
    return result;
  }

  if (typeName === 'enum') {
    const enumSchema = innerSchema as z.ZodEnum<[string, ...string[]]>;
    const result: Record<string, unknown> = { type: 'string', enum: enumSchema.options };
    if (description) result.description = description;
    return result;
  }

  if (typeName === 'array') {
    const result: Record<string, unknown> = { type: 'array', items: zodTypeToJsonSchema((innerSchema as z.ZodArray<z.ZodType>).element) };
    if (description) result.description = description;
    return result;
  }

  const result: Record<string, unknown> = { type: 'string' };
  if (description) result.description = description;
  return result;
}

// Global rules that apply to all tools
export const GLOBAL_TOOL_RULES = "Always respond in the same language the user is using. Match the user's tone and communication style - be casual if they're casual, technical if they're technical. Adapt to their lingo.";
