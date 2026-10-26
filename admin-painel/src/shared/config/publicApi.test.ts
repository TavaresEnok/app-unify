import { describe, expect, it } from "vitest";
import { resolvePublicApiBaseUrl } from "./publicApi";

describe("resolvePublicApiBaseUrl", () => {
  it("uses the configured deployment URL when provided", () => {
    expect(resolvePublicApiBaseUrl(" https://api.example.com/ ")).toBe("https://api.example.com");
  });

  it("uses the frontend API proxy on the direct frontend and Caddy ports", () => {
    expect(resolvePublicApiBaseUrl(undefined, {
      protocol: "http:", hostname: "192.0.2.10", port: "8031", origin: "http://192.0.2.10:8031",
    })).toBe("http://192.0.2.10:8031/api");
    expect(resolvePublicApiBaseUrl(undefined, {
      protocol: "http:", hostname: "192.0.2.10", port: "8080", origin: "http://192.0.2.10:8080",
    })).toBe("http://192.0.2.10:8080/api");
  });

  it("detects the public API port when the panel is accessed on port 80", () => {
    expect(resolvePublicApiBaseUrl(undefined, {
      protocol: "http:", hostname: "192.0.2.10", port: "", origin: "http://192.0.2.10",
    })).toBe("http://192.0.2.10:8034");
  });
});
