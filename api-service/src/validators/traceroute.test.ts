import { describe, expect, it } from "vitest";
import { isValidTracerouteTarget, normalizeMaxHops, parseTracerouteOutput } from "./traceroute";

describe("traceroute validation", () => {
  it("accepts public addresses and hostnames", () => {
    expect(isValidTracerouteTarget("8.8.8.8")).toBe(true);
    expect(isValidTracerouteTarget("dns.google")).toBe(true);
  });

  it("blocks private networks and command options", () => {
    expect(isValidTracerouteTarget("127.0.0.1")).toBe(false);
    expect(isValidTracerouteTarget("192.168.1.1")).toBe(false);
    expect(isValidTracerouteTarget("-T")).toBe(false);
    expect(isValidTracerouteTarget("8.8.8.8;id")).toBe(false);
  });

  it("normalizes hop limits", () => {
    expect(normalizeMaxHops(100)).toBe(30);
    expect(normalizeMaxHops(0)).toBe(1);
    expect(normalizeMaxHops("invalid")).toBe(15);
  });

  it("parses traceroute output", () => {
    expect(parseTracerouteOutput("traceroute to x\n 1  8.8.8.8  12.5 ms\n")).toEqual([
      { hop: 1, ip: "8.8.8.8", time: "12.5 ms" },
    ]);
  });
});
