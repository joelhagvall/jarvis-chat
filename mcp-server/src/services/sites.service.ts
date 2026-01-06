import type { Site, SitesResponse } from './sl-types.js';

const TRANSPORT_BASE_URL = 'https://transport.integration.sl.se/v1';

export class SitesService {
  private sitesCache: Site[] | null = null;
  private cacheTimestamp: number = 0;
  private readonly CACHE_TTL = 24 * 60 * 60 * 1000; // 24 hours

  async getAllSites(): Promise<Site[]> {
    const now = Date.now();

    // Return cached data if it's still valid
    if (this.sitesCache && (now - this.cacheTimestamp) < this.CACHE_TTL) {
      return this.sitesCache;
    }

    try {
      const response = await fetch(`${TRANSPORT_BASE_URL}/sites?expand=false`, {
        headers: {
          'accept': 'application/json',
          'Accept-Encoding': 'identity',
        },
      });

      if (!response.ok) {
        throw new Error(`Sites API error: ${String(response.status)} ${response.statusText}`);
      }

      const data = (await response.json()) as SitesResponse;
      this.sitesCache = data;
      this.cacheTimestamp = now;

      return this.sitesCache;
    } catch (error) {
      console.error('Error fetching sites:', error);
      // Return cached data even if expired, if available
      if (this.sitesCache !== null) {
        return this.sitesCache;
      }
      throw error;
    }
  }

  async findStation(query: string): Promise<Site | null> {
    const sites = await this.getAllSites();
    const normalizedQuery = this.normalizeString(query);

    // First try exact match
    let match = sites.find(site =>
      this.normalizeString(site.name) === normalizedQuery
    );

    if (match !== undefined) return match;

    // Try starts with match
    match = sites.find(site =>
      this.normalizeString(site.name).startsWith(normalizedQuery)
    );

    if (match !== undefined) return match;

    // Try contains match
    match = sites.find(site =>
      this.normalizeString(site.name).includes(normalizedQuery)
    );

    if (match !== undefined) return match;

    // Try fuzzy match (handles typos and variations)
    const fuzzyMatches = sites
      .map(site => ({
        site,
        score: this.calculateSimilarity(normalizedQuery, this.normalizeString(site.name)),
      }))
      .filter(({ score }) => score > 0.7)
      .sort((a, b) => b.score - a.score);

    const bestMatch = fuzzyMatches[0];
    return bestMatch?.site ?? null;
  }

  private normalizeString(str: string): string {
    return str
      .toLowerCase()
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '') // Remove diacritics
      .replace(/[öø]/g, 'o')
      .replace(/[äæ]/g, 'a')
      .replace(/å/g, 'a')
      .replace(/\s+(t-bana|tbana|station|metro|tunnelbana|busshallplats|pendeltag)$/i, '') // Remove common suffixes
      .trim();
  }

  private calculateSimilarity(str1: string, str2: string): number {
    const longer = str1.length > str2.length ? str1 : str2;
    const shorter = str1.length > str2.length ? str2 : str1;

    if (longer.length === 0) {
      return 1.0;
    }

    const editDistance = this.levenshteinDistance(longer, shorter);
    return (longer.length - editDistance) / longer.length;
  }

  private levenshteinDistance(str1: string, str2: string): number {
    const m = str1.length;
    const n = str2.length;

    // Use two rows instead of full matrix for O(min(m,n)) space
    let prevRow = new Array<number>(n + 1);
    let currRow = new Array<number>(n + 1);

    // Initialize first row
    for (let j = 0; j <= n; j++) {
      prevRow[j] = j;
    }

    for (let i = 1; i <= m; i++) {
      currRow[0] = i;

      for (let j = 1; j <= n; j++) {
        const cost = str1.charAt(i - 1) === str2.charAt(j - 1) ? 0 : 1;
        const prevRowJ = prevRow[j] ?? 0;
        const prevRowJMinus1 = prevRow[j - 1] ?? 0;
        const currRowJMinus1 = currRow[j - 1] ?? 0;

        currRow[j] = Math.min(
          prevRowJ + 1,           // deletion
          currRowJMinus1 + 1,     // insertion
          prevRowJMinus1 + cost   // substitution
        );
      }

      // Swap rows
      [prevRow, currRow] = [currRow, prevRow];
    }

    return prevRow[n] ?? 0;
  }
}

// Singleton instance
export const sitesService = new SitesService();
