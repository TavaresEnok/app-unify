import { expect, it, vi } from "vitest";
vi.mock("@/shared/auth/session", () => ({ auth: { currentUser: null } }));
import { absoluteAssetUrl, assetFileError } from "./assets";

it("stores absolute URLs the subscriber app can load", () => {
  expect(absoluteAssetUrl("/api/public/assets/vibe/a.png", "https://appisp.com.br/api")).toBe("https://appisp.com.br/api/public/assets/vibe/a.png");
  expect(absoluteAssetUrl("/api/public/assets/vibe/a.png", "https://appisp.com.br/api/")).toBe("https://appisp.com.br/api/public/assets/vibe/a.png");
  expect(absoluteAssetUrl("https://cdn.example/a.png", "https://appisp.com.br/api")).toBe("https://cdn.example/a.png");
});

it("uses the panel origin when the API base is relative (VITE_API_URL=/api in production)", () => {
  expect(absoluteAssetUrl("/api/public/assets/vibe/a.png", "/api", "https://appisp.com.br")).toBe("https://appisp.com.br/api/public/assets/vibe/a.png");
  expect(absoluteAssetUrl("/api/public/assets/vibe/a.png", "", "https://appisp.com.br/")).toBe("https://appisp.com.br/api/public/assets/vibe/a.png");
  expect(() => absoluteAssetUrl("/api/public/assets/vibe/a.png", "/api", "")).toThrow();
});

it("accepts only PNG, JPG and WebP", () => {
  expect(assetFileError({ type: "image/png", size: 10 })).toBeNull();
  expect(assetFileError({ type: "image/gif", size: 10 })).toMatch(/PNG, JPG ou WebP/);
});
