#!/usr/bin/env node

/**
 * MCP Server CLI Entry Point
 *
 * This script starts the MCP server using stdio transport.
 *
 * Usage:
 *   npx mcp-server
 *   node bin/server.js
 *
 * Environment variables:
 *   MCP_SERVER_NAME    - Custom server name (default: "mcp-server")
 *   MCP_SERVER_VERSION - Custom version (default: "1.0.0")
 *   NOTION_API_KEY     - Notion integration token for search_notion tool
 */

import { startServer } from '../dist/server.js';

startServer().catch((error) => {
  console.error('Failed to start MCP server:', error);
  process.exit(1);
});
