import { z } from 'zod';
import type { ToolDefinition } from '../types.js';

// Dynamic import for systeminformation (optional dependency)
let si: typeof import('systeminformation') | null = null;

async function loadSystemInfo() {
  if (!si) {
    try {
      si = await import('systeminformation');
    } catch {
      return null;
    }
  }
  return si;
}

function formatBytes(bytes: number): string {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return `${(bytes / Math.pow(k, i)).toFixed(1)} ${sizes[i]}`;
}

function formatUptime(seconds: number): string {
  const days = Math.floor(seconds / 86400);
  const hours = Math.floor((seconds % 86400) / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  const parts: string[] = [];
  if (days > 0) parts.push(`${days}d`);
  if (hours > 0) parts.push(`${hours}h`);
  if (minutes > 0) parts.push(`${minutes}m`);
  return parts.join(' ') || '< 1m';
}

const systemInfoSchema = z.object({});

export const systemInfoTool: ToolDefinition<typeof systemInfoSchema> = {
  name: 'get_system_info',
  description: 'Get current system information including CPU load, memory usage, disk space, network status, GPU info, and uptime. Use this tool when the user asks about their computer, system stats, performance, or hardware.',
  schema: systemInfoSchema,
  execute: async () => {
    const systemInfo = await loadSystemInfo();

    if (!systemInfo) {
      return 'System information not available. Install "systeminformation" package to enable this feature.';
    }

    try {
      const [osInfo, cpu, mem, disk, graphics, wifiNetworks, time] = await Promise.all([
        systemInfo.osInfo(),
        systemInfo.currentLoad(),
        systemInfo.mem(),
        systemInfo.fsSize(),
        systemInfo.graphics(),
        systemInfo.wifiConnections(),
        systemInfo.time(),
      ]);

      const currentWifi = wifiNetworks.length > 0 ? wifiNetworks[0] : null;

      const lines: string[] = [
        '=== System Information ===',
        '',
        'SYSTEM',
        `  OS: ${osInfo.distro} ${osInfo.release}`,
        `  Hostname: ${osInfo.hostname}`,
        `  Platform: ${osInfo.platform}`,
        '',
        'CPU',
        `  Load: ${cpu.currentLoad.toFixed(1)}%`,
        `  Cores: ${cpu.cpus.length}`,
        '',
        'MEMORY',
        `  Used: ${formatBytes(mem.used)} / ${formatBytes(mem.total)}`,
        `  Usage: ${((mem.used / mem.total) * 100).toFixed(1)}%`,
        `  Free: ${formatBytes(mem.free)}`,
        '',
        'STORAGE',
      ];

      disk.forEach(d => {
        lines.push(`  ${d.fs}: ${formatBytes(d.used)} / ${formatBytes(d.size)} (${d.use.toFixed(1)}%)`);
      });

      if (graphics.controllers.length > 0) {
        lines.push('');
        lines.push('GRAPHICS');
        graphics.controllers.forEach(g => {
          lines.push(`  ${g.model}${g.vram ? ` (${g.vram} MB VRAM)` : ''}`);
        });
      }

      if (currentWifi) {
        lines.push('');
        lines.push('NETWORK');
        lines.push(`  WiFi: ${currentWifi.ssid}`);
        lines.push(`  Signal: ${currentWifi.signalLevel} dBm`);
      }

      lines.push('');
      lines.push(`Uptime: ${formatUptime(time.uptime)}`);
      lines.push(`Report time: ${new Date().toLocaleString()}`);

      return lines.join('\n');
    } catch (error) {
      return `Failed to get system info: ${error instanceof Error ? error.message : 'Unknown error'}`;
    }
  },
};
