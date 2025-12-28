import { exec } from 'child_process';
import { z } from 'zod';
import type { ToolDefinition } from '../types.js';

const notesSchema = z.object({
  search: z.string().describe('Search query to find notes containing this text. Uses Spotlight for fast search across all notes.').optional(),
  limit: z.number().describe('Maximum number of notes to return (default: 5)').optional(),
});

export const notesTool: ToolDefinition<typeof notesSchema> = {
  name: 'get_notes',
  description: 'Fetches or searches notes from the macOS Notes app. Use "search" to find old notes by keyword. When presenting notes to the user: show the title, briefly summarize the content in 2-3 sentences, and list key bullet points if relevant. Keep it readable but not overwhelming. End by mentioning that the user can ask follow-up questions about the note.',
  schema: notesSchema,
  execute: async (args) => {
    const limit = args.limit ?? 5;
    const search = args.search?.trim();

    // If searching, use AppleScript's "whose" filter - much faster than manual loop
    if (search) {
      const searchScript = `
        set output to ""
        tell application "Notes"
          set matchingNotes to (every note whose name contains "${search}")
          set noteCount to 0
          repeat with n in matchingNotes
            if noteCount >= ${limit} then exit repeat
            try
              set noteName to name of n
              set noteBody to plaintext of n
              set noteModified to modification date of n as string
              set output to output & noteName & " (" & noteModified & ")" & linefeed
              set output to output & noteBody & linefeed & linefeed
              set noteCount to noteCount + 1
            end try
          end repeat
        end tell
        return output
      `;

      return new Promise((resolve) => {
        exec(
          `osascript -e '${searchScript.replace(/'/g, "'\"'\"'")}'`,
          { maxBuffer: 1024 * 1024 * 10, timeout: 30000 },
          (error, stdout) => {
            if (error || !stdout.trim()) {
              resolve(`Hittade inga anteckningar med "${search}" i titeln.`);
            } else {
              resolve(stdout.trim());
            }
          }
        );
      });
    }

    // No search - just get recent notes
    const appleScript = `
      set output to ""
      tell application "Notes"
        set noteCount to 0
        set maxNotes to ${limit}
        set allNotes to every note
        repeat with n in allNotes
          if noteCount >= maxNotes then exit repeat
          try
            set noteName to name of n
            set noteBody to plaintext of n
            set noteModified to modification date of n as string
            set output to output & noteName & " (" & noteModified & ")" & linefeed
            set output to output & noteBody & linefeed & linefeed
            set noteCount to noteCount + 1
          end try
        end repeat
      end tell
      return output
    `;

    return new Promise((resolve) => {
      exec(
        `osascript -e '${appleScript.replace(/'/g, "'\"'\"'")}'`,
        { maxBuffer: 1024 * 1024 * 10, timeout: 30000 },
        (error, stdout) => {
          if (error) {
            resolve(`Failed to fetch notes: ${error.message}. Make sure the app has access to Notes in System Settings > Privacy & Security > Automation.`);
          } else {
            resolve(stdout.trim() || 'No notes found.');
          }
        }
      );
    });
  },
};
