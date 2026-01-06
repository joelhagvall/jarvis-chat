import type {
  TripPlannerResponse,
  Journey,
  Leg,
  TripPlanData,
  LegData,
  StopFinderResponse,
  StopFinderLocation,
  Location,
} from './sl-types.js';

// Extended location with time fields (as returned by the API)
interface LocationWithTime extends Location {
  departureTimeEstimated?: string;
  departureTimePlanned?: string;
  arrivalTimeEstimated?: string;
  arrivalTimePlanned?: string;
}

const JOURNEY_PLANNER_BASE_URL = 'https://journeyplanner.integration.sl.se/v2';
const STOP_FINDER_ENDPOINT = `${JOURNEY_PLANNER_BASE_URL}/stop-finder`;

export class TripPlannerService {
  async planTrip(
    origin: string,
    destination: string,
    numberOfTrips: number = 3
  ): Promise<TripPlanData[]> {
    try {
      // Look up locations using Journey-planner stop-finder
      const originLocationId = await this.findLocationId(origin);
      const destinationLocationId = await this.findLocationId(destination);

      if (originLocationId === null) {
        throw new Error(`Could not find station matching "${origin}". Please check the station name and try again.`);
      }

      if (destinationLocationId === null) {
        throw new Error(`Could not find station matching "${destination}". Please check the station name and try again.`);
      }

      // Always use current time for fresh results
      const now = new Date();
      const itdDate = now.toISOString().slice(0, 10).replace(/-/g, ''); // YYYYMMDD
      const itdTime = now.toTimeString().slice(0, 5).replace(':', '');  // HHMM

      const params = new URLSearchParams({
        type_origin: 'any',
        name_origin: originLocationId,
        type_destination: 'any',
        name_destination: destinationLocationId,
        calc_number_of_trips: numberOfTrips.toString(),
        itdDate,
        itdTime,
      });

      const url = `${JOURNEY_PLANNER_BASE_URL}/trips?${params.toString()}`;
      const response = await fetch(url);

      if (!response.ok) {
        throw new Error(`Journey Planner API error: ${String(response.status)} ${response.statusText}`);
      }

      const data = (await response.json()) as TripPlannerResponse;

      if (data.journeys === undefined || data.journeys.length === 0) {
        throw new Error('No journeys found for the specified route');
      }

      // Filter out journeys that have already departed
      const futureJourneys = data.journeys.filter(journey => {
        if (journey.legs.length === 0) return false;
        const firstOrigin = journey.legs[0]?.origin as LocationWithTime | undefined;
        const depTimeStr = firstOrigin?.departureTimeEstimated ?? firstOrigin?.departureTimePlanned;
        if (!depTimeStr) return false;
        const depTime = new Date(depTimeStr);
        return depTime >= now;
      });

      return this.transformJourneys(futureJourneys);
    } catch (error) {
      console.error('Error planning trip:', error);
      throw error;
    }
  }

  private async findLocationId(query: string): Promise<string | null> {
    const params = new URLSearchParams({
      name_sf: query,
      any_obj_filter_sf: '2',
      type_sf: 'any',
    });

    const url = `${STOP_FINDER_ENDPOINT}?${params.toString()}`;
    const response = await fetch(url);

    if (!response.ok) {
      throw new Error(`Stop-finder API error: ${String(response.status)} ${response.statusText}`);
    }

    const data = (await response.json()) as StopFinderResponse;
    const locations = data.locations ?? [];

    if (locations.length === 0) {
      return null;
    }

    const bestFromIsBest = locations.find(location => location.isBest === true);
    const bestFromSort = this.sortByMatchQuality(locations)[0];
    const best = bestFromIsBest ?? bestFromSort;

    return best?.id ?? null;
  }

  private sortByMatchQuality(locations: StopFinderLocation[]): StopFinderLocation[] {
    return [...locations].sort((a, b) => {
      const scoreA = a.matchQuality ?? 0;
      const scoreB = b.matchQuality ?? 0;
      return scoreB - scoreA;
    });
  }

  private transformJourneys(journeys: Journey[]): TripPlanData[] {
    return journeys.map(journey => {
      if (journey.legs.length === 0) {
        return {
          duration: this.formatDuration(journey.tripRtDuration ?? journey.tripDuration),
          interchanges: journey.interchanges,
          departureTime: '',
          arrivalTime: '',
          legs: [],
        };
      }

      const firstLeg = journey.legs[0];
      const lastLeg = journey.legs[journey.legs.length - 1];

      // Times are nested in origin/destination objects
      const firstOrigin = firstLeg?.origin as LocationWithTime | undefined;
      const lastDest = lastLeg?.destination as LocationWithTime | undefined;
      const departureTime = firstOrigin?.departureTimeEstimated ?? firstOrigin?.departureTimePlanned ?? '';
      const arrivalTime = lastDest?.arrivalTimeEstimated ?? lastDest?.arrivalTimePlanned ?? '';

      return {
        duration: this.formatDuration(journey.tripRtDuration ?? journey.tripDuration),
        interchanges: journey.interchanges,
        departureTime: this.formatTime(departureTime),
        arrivalTime: this.formatTime(arrivalTime),
        legs: this.transformLegs(journey.legs),
      };
    });
  }

  private transformLegs(legs: Leg[]): LegData[] {
    return legs.map(leg => {
      const transport = leg.transportation !== undefined
        ? `${leg.transportation.product.name} ${leg.transportation.number ?? ''}`.trim()
        : 'Walk';

      const line = leg.transportation?.number ?? leg.transportation?.name;

      // Times are nested inside origin/destination objects
      const depTime = (leg.origin as LocationWithTime)?.departureTimeEstimated
        ?? (leg.origin as LocationWithTime)?.departureTimePlanned
        ?? '';
      const arrTime = (leg.destination as LocationWithTime)?.arrivalTimeEstimated
        ?? (leg.destination as LocationWithTime)?.arrivalTimePlanned
        ?? '';

      return {
        from: leg.origin.name,
        to: leg.destination.name,
        departureTime: this.formatTime(depTime),
        arrivalTime: this.formatTime(arrTime),
        line,
        transport,
      };
    });
  }

  private formatDuration(seconds: number): string {
    const minutes = Math.floor(seconds / 60);
    const hours = Math.floor(minutes / 60);
    const remainingMinutes = minutes % 60;

    if (hours > 0) {
      return `${String(hours)}h ${String(remainingMinutes)}min`;
    }
    return `${String(minutes)}min`;
  }

  private formatTime(isoTime: string): string {
    if (isoTime === '') return '';

    try {
      const date = new Date(isoTime);
      return date.toLocaleTimeString('sv-SE', {
        hour: '2-digit',
        minute: '2-digit'
      });
    } catch {
      return isoTime;
    }
  }
}

// Singleton instance
export const tripPlannerService = new TripPlannerService();
