import { expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { parsePersonalization, sanitizePersonalization, publicProviderData } from "./providerConfig";
it("standalone boundary mirrors equal the canonical schema", () => {
 const canonical = readFileSync(new URL("../../../shared/runtime/providerConfig.ts", import.meta.url), "utf8");
 for (const path of ["./providerConfig.ts", "../../../api-service/src/services/providerConfig.ts", "../../../admin-painel/src/features/provider-settings/configBoundary.ts"])
  expect(readFileSync(new URL(path, import.meta.url), "utf8")).toBe(canonical);
});
it("validates encoded layout themes recursively on input and legacy output", () => {
 const themes = { layout_01: { themeColor: "#123456" }, layout_06: { textColor: "#ffffff" } };
 const config = { strings: { layoutThemes: JSON.stringify(themes) } };
 expect(parsePersonalization(config)).toEqual(config);
 expect(publicProviderData(config)).toEqual(config);
 for (const value of [
  "{broken", "null", "[]", JSON.stringify({ unknown: { themeColor: "#123456" } }),
  JSON.stringify({ layout_06: { apiToken: "synthetic" } }),
  JSON.stringify({ layout_06: { unknown: "synthetic" } }),
  JSON.stringify({ layout_06: { themeColor: { secretRef: "synthetic" } } }),
 ]) expect(() => parsePersonalization({ strings: { layoutThemes: value } })).toThrow();
 const legacy = { strings: { layoutThemes: JSON.stringify({ ...themes, secretRef: "synthetic", layout_02: { themeColor: "#abcdef", token: "synthetic" } }) } };
 expect(JSON.parse((publicProviderData(legacy).strings as any).layoutThemes)).toEqual({
  ...themes, layout_02: { themeColor: "#abcdef" },
 });
 expect(sanitizePersonalization({ strings: { layoutThemes: "{broken" } })).toEqual({ strings: {} });
});
it("rejects unknown nested array fields and preserves supported customization", () => {
 const valid = { other: { useBackgroundImage: true, showTvService: false, showPhoneService: true }, menuConfig: { order: ["external_123"], items: { external_123: { enabled: true, type: "external_link", url: "https://brand.test", color: "#fff", name: "Site" } } }, features: { payment_promise: true },
  dashboardConfig: { widgets: [{ id: "w", type: "banner", position: 0, visible: true, config: { imageUrl: "", height: 150, borderRadius: 16 } }] } };
 expect(parsePersonalization(valid)).toEqual(valid);
 expect(() => parsePersonalization({ ...valid, dashboardConfig: { widgets: [{ config: { apiToken: "synthetic" } }] } })).toThrow();
 expect(sanitizePersonalization({ config: { themeColor: "old" }, themeColor: "new", token: "synthetic" })).toEqual({ themeColor: "new" });
});
