function isPrivateIpv4(octets: number[]): boolean {
  const [a, b] = octets;
  return a === 10 || (a === 172 && b >= 16 && b <= 31) || a === 192 && b === 168 ||
    a === 127 || a === 0 || a === 169 && b === 254 || a >= 224;
}

export function isValidTracerouteTarget(target: string): boolean {
  if (!target || target.length > 253 || /[^a-zA-Z0-9.-]/.test(target) || target.startsWith("-")) return false;
  const match = target.match(/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/);
  if (match) {
    const octets = match.slice(1).map((value) => Number(value));
    return !octets.some((value) => value > 255) && !isPrivateIpv4(octets);
  }
  return /[a-zA-Z]/.test(target) && !target.includes("..") && !target.endsWith(".");
}

export function normalizeMaxHops(value: unknown): number {
  const hops = Number(value);
  return Number.isFinite(hops) ? Math.min(Math.max(Math.floor(hops), 1), 30) : 15;
}

export function parseTracerouteOutput(stdout: string) {
  return stdout.split("\n").flatMap((line) => {
    if (line.includes("traceroute to")) return [];
    const match = line.match(/^\s*(\d+)\s+(\S+)\s+(.+)/);
    if (!match) return [];
    const time = match[3].match(/(\d+\.?\d*)\s*ms/);
    return [{ hop: Number(match[1]), ip: match[2], time: time ? `${time[1]} ms` : "*" }];
  });
}
