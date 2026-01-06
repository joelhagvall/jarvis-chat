import type { SLTransportResponse, Departure, DepartureDisplayData } from './sl-types.js';

const SL_API_BASE_URL = 'https://transport.integration.sl.se/v1/sites';

export class SLApiService {
  async getDepartures(siteId: string): Promise<DepartureDisplayData[]> {
    try {
      const url = `${SL_API_BASE_URL}/${siteId}/departures`;
      const response = await fetch(url);

      if (!response.ok) {
        throw new Error(`SL API error: ${String(response.status)} ${response.statusText}`);
      }

      const data = (await response.json()) as SLTransportResponse;
      return this.transformDepartures(data.departures);
    } catch (error) {
      console.error('Error fetching SL departures:', error);
      throw error;
    }
  }

  private transformDepartures(departures: Departure[]): DepartureDisplayData[] {
    return departures
      .map(dep => ({
        line: dep.line.designation,
        destination: dep.destination,
        displayTime: dep.display,
        transportMode: dep.line.transport_mode.toLowerCase(),
        deviations: dep.deviations?.map(d => d.message) ?? []
      }))
      .sort((a, b) => {
        const timeA = this.parseDisplayTime(a.displayTime);
        const timeB = this.parseDisplayTime(b.displayTime);
        return timeA - timeB;
      });
  }

  private parseDisplayTime(displayTime: string): number {
    if (displayTime.toLowerCase() === 'nu') return 0;
    const match = displayTime.match(/\d+/);
    const firstMatch = match?.[0];
    return firstMatch !== undefined ? parseInt(firstMatch, 10) : 999;
  }
}

// Singleton instance
export const slApiService = new SLApiService();
