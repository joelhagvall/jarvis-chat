import { z } from 'zod';
import type { ToolDefinition } from '../types.js';
import { tripPlannerService } from '../services/trip-planner.service.js';

const slTripPlannerSchema = z.object({
  origin: z.string().describe('Start station from user message'),
  destination: z.string().describe('End station from user message'),
});

export const slTripPlannerTool: ToolDefinition<typeof slTripPlannerSchema> = {
  name: 'plan_sl_trip',
  description: 'Plan trip in Stockholm. Example: User says "how to get from Gärdet to Slussen" → call with origin="Gärdet", destination="Slussen"',
  schema: slTripPlannerSchema,
  execute: async (args) => {
    try {
      const trips = await tripPlannerService.planTrip(
        args.origin,
        args.destination,
        3
      );

      if (trips.length === 0) {
        return 'No viable routes detected between these locations.';
      }

      // Format with bullets and spacing
      const options = trips.slice(0, 3).map((trip, i) => {
        const steps = trip.legs
          .filter(leg => !leg.transport.toLowerCase().includes('foot') && !leg.transport.toLowerCase().includes('walk'))
          .map(leg => {
            const line = leg.line || leg.transport;
            const from = leg.from.split(',')[0];
            const to = leg.to.split(',')[0];
            return `  • ${leg.departureTime} ${from} → ${leg.arrivalTime} ${to} (${line})`;
          });

        return `**Alternativ ${i + 1}** — Avgår ${trip.departureTime}, framme ${trip.arrivalTime} (${trip.duration})\n${steps.join('\n')}`;
      });

      return options.join('\n\n');
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      return `Failed to plan trip: ${message}`;
    }
  },
};
