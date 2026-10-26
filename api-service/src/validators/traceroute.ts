import { lookup } from "node:dns/promises";

export function isPrivateIpv4(octets: number[]): boolean {
  const [a, b] = octets;
  return a === 10 || (a === 172 && b >= 16 && b <= 31) || (a === 192 && b === 168) ||
    a === 127 || a === 0 || (a === 169 && b === 254) ||
    (a === 100 && b >= 64 && b <= 127) || a >= 224;
}

function isPublicIpv4Literal(target: string): boolean {
  const match = target.match(/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/);
  if (!match) return false;
  const octets = match.slice(1).map((value) => Number(value));
  return !octets.some((value) => value > 255) && !isPrivateIpv4(octets);
}

/**
 * Validação SINTÁTICA apenas (formato do alvo). A validação de destino real —
 * que impede SSRF para faixas internas — é feita em resolveSafeTracerouteTarget,
 * que resolve o DNS e revalida cada endereço.
 */
export function isValidTracerouteTarget(target: string): boolean {
  if (!target || target.length > 253 || /[^a-zA-Z0-9.-]/.test(target) || target.startsWith("-")) return false;
  if (/^\d{1,3}(\.\d{1,3}){3}$/.test(target)) return isPublicIpv4Literal(target);
  return /[a-zA-Z]/.test(target) && !target.includes("..") && !target.endsWith(".");
}

/**
 * Resolve o alvo e garante que TODO endereço IPv4 resolvido é público, evitando
 * SSRF / DNS-rebinding para faixas internas (10/8, 172.16/12, 192.168/16, 127/8,
 * 169.254/16 metadata, 100.64/10 CGNAT, multicast/reservado). Retorna um IP
 * público para "fixar" o alvo — impede que o traceroute resolva um IP diferente
 * do que foi validado. Lança se o host não resolve ou aponta para faixa privada.
 */
export async function resolveSafeTracerouteTarget(target: string): Promise<string> {
  if (isPublicIpv4Literal(target)) return target;
  const addresses = await lookup(target, { all: true, family: 4 }).catch(() => [] as { address: string }[]);
  if (!addresses.length) throw new Error("Destino não pôde ser resolvido.");
  for (const { address } of addresses) {
    if (!isPublicIpv4Literal(address)) throw new Error("Destino resolve para endereço não permitido.");
  }
  return addresses[0].address;
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
