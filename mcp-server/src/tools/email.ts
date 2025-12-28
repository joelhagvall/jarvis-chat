import { exec } from 'child_process';
import { z } from 'zod';
import type { ToolDefinition } from '../types.js';

const emailSchema = z.object({
  to: z.string().describe('Email address of the recipient'),
  subject: z.string().describe('Email subject line'),
  body: z.string().describe('Email body content'),
});

export const emailTool: ToolDefinition<typeof emailSchema> = {
  name: 'send_email_report',
  description: 'Opens the default mail client with a pre-composed email. Use this when the user wants to email information to someone.',
  schema: emailSchema,
  execute: async (args) => {
    const { to, subject, body } = args;

    const mailto = `mailto:${encodeURIComponent(to)}?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}`;

    return new Promise((resolve) => {
      exec(`open "${mailto}"`, (error) => {
        if (error) {
          resolve(`Failed to open mail client: ${error.message}`);
        } else {
          resolve(`Mail client opened with email to ${to}`);
        }
      });
    });
  },
};
