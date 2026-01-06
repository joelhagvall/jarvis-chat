import { z } from 'zod';
import type { ToolDefinition } from '../types.js';
import { slApiService } from '../services/sl-api.service.js';
import { sitesService } from '../services/sites.service.js';

const slDeparturesSchema = z.object({
  stationName: z.string().describe('Station name from user message'),
});

export const slDeparturesTool: ToolDefinition<typeof slDeparturesSchema> = {
  name: 'get_sl_departures',
  description: 'Get train/bus/metro departures. Example: User says "departures from Odenplan" → call with stationName="Odenplan"',
  schema: slDeparturesSchema,
  execute: async (args) => {
    try {
      const siteId = await resolveSiteId(args);
      const departures = await slApiService.getDepartures(siteId);

      if (departures.length === 0) {
        return 'No active transport units detected at this location.';
      }

      // Group by transport mode
      const metro = departures.filter(d => d.transportMode === 'metro');
      const bus = departures.filter(d => d.transportMode === 'bus');
      const train = departures.filter(d => d.transportMode === 'train' || d.transportMode === 'tram');

      const formatDeparture = (dep: typeof departures[0]) => {
        const urgency = dep.displayTime.toLowerCase() === 'nu' ? '► BOARDING NOW' : dep.displayTime;
        let line = `  ${dep.line} → ${dep.destination} | ${urgency}`;
        if (dep.deviations.length > 0) {
          line += ` ⚠️ ${dep.deviations.join(', ')}`;
        }
        return line;
      };

      const sections: string[] = [];

      if (metro.length > 0) {
        sections.push(`🚇 METRO\n${metro.slice(0, 4).map(formatDeparture).join('\n')}`);
      }
      if (bus.length > 0) {
        sections.push(`🚌 BUS\n${bus.slice(0, 4).map(formatDeparture).join('\n')}`);
      }
      if (train.length > 0) {
        sections.push(`🚃 TRAIN/TRAM\n${train.slice(0, 4).map(formatDeparture).join('\n')}`);
      }

      const nextDeparture = departures[0];
      const recommendation = nextDeparture?.displayTime.toLowerCase() === 'nu'
        ? 'Immediate departure available.'
        : `Next departure in ${nextDeparture?.displayTime}.`;

      return `TRANSPORT SCAN COMPLETE\n\n${sections.join('\n\n')}\n\n${recommendation}`;
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      return `Failed to fetch departures: ${message}`;
    }
  },
};

async function resolveSiteId(args: { stationName: string }): Promise<string> {
  const station = await sitesService.findStation(args.stationName);

  if (station === null) {
    throw new Error(`Could not find station "${args.stationName}".`);
  }

  return String(station.id);
}
