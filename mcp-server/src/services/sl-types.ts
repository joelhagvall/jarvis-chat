export interface SLTransportResponse {
  departures: Departure[];
}

export interface Departure {
  line: {
    designation: string;
    transport_mode: string;
  };
  destination: string;
  display: string;
  deviations?: Array<{ message: string }>;
}

export interface DepartureDisplayData {
  line: string;
  destination: string;
  displayTime: string;
  transportMode: string;
  deviations: string[];
}

export interface TripPlannerResponse {
  journeys?: Journey[];
  systemMessages?: Array<{ message: string }>;
}

export interface StopFinderLocation {
  id: string;
  isGlobalId?: boolean;
  name: string;
  disassembledName?: string;
  coord?: [number, number];
  type?: string;
  matchQuality?: number;
  isBest?: boolean;
  productClasses?: number[];
  parent?: {
    id: string;
    name: string;
    type: string;
  };
  properties?: Record<string, unknown>;
}

export interface StopFinderResponse {
  locations?: StopFinderLocation[];
  systemMessages?: Array<{
    type: string;
    module: string;
    code: number;
    text: string;
    subType?: string;
  }>;
}

export interface Journey {
  tripId: string;
  tripDuration: number;
  tripRtDuration?: number;
  interchanges: number;
  legs: Leg[];
}

export interface Leg {
  origin: Location;
  destination: Location;
  departureTimeEstimated?: string;
  departureTimePlanned?: string;
  arrivalTimeEstimated?: string;
  arrivalTimePlanned?: string;
  duration: number;
  transportation?: Transportation;
  stopSequence?: Stop[];
}

export interface Location {
  id: string;
  name: string;
  type: string;
  coord?: [number, number];
}

export interface Transportation {
  id: string;
  name: string;
  number?: string;
  product: {
    id: string;
    name: string;
    type: string;
  };
}

export interface Stop {
  id: string;
  name: string;
  departureTimeEstimated?: string;
  arrivalTimeEstimated?: string;
}

export interface TripPlanData {
  duration: string;
  interchanges: number;
  departureTime: string;
  arrivalTime: string;
  legs: LegData[];
}

export interface LegData {
  from: string;
  to: string;
  departureTime: string;
  arrivalTime: string;
  line?: string | undefined;
  transport: string;
}

export interface Site {
  id: number;
  gid: number;
  name: string;
  note?: string;
  lat: number;
  lon: number;
  valid?: {
    from: string;
    to?: string;
  };
}

export type SitesResponse = Site[];
