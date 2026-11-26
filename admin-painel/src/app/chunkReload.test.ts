import { describe, expect, it, vi } from "vitest";
import { isChunkLoadError, reloadOnceForChunkError } from "./chunkReload";

function memoryStorage() {
  const data = new Map<string, string>();
  return { getItem: (k: string) => data.get(k) ?? null, setItem: (k: string, v: string) => { data.set(k, v); } };
}

describe("chunk reload after deploy", () => {
  it("recognizes missing lazy chunk errors", () => {
    expect(isChunkLoadError(new TypeError("Failed to fetch dynamically imported module: https://x/assets/a.js"))).toBe(true);
    expect(isChunkLoadError(new Error("Importing a module script failed."))).toBe(true);
    expect(isChunkLoadError(new Error("Cannot read properties of undefined (reading 'name')"))).toBe(false);
  });

  it("reloads only once per minute", () => {
    const storage = memoryStorage();
    const reload = vi.fn();
    let now = 1_000_000;
    expect(reloadOnceForChunkError({ storage, reload, now: () => now })).toBe(true);
    expect(reloadOnceForChunkError({ storage, reload, now: () => now + 5_000 })).toBe(false);
    now += 61_000;
    expect(reloadOnceForChunkError({ storage, reload, now: () => now })).toBe(true);
    expect(reload).toHaveBeenCalledTimes(2);
  });

  it("does not reload without session storage (avoids loops)", () => {
    const reload = vi.fn();
    expect(reloadOnceForChunkError({ storage: null, reload })).toBe(false);
    expect(reload).not.toHaveBeenCalled();
  });
});
