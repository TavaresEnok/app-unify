import { expect, it, vi } from "vitest";
import { renderToStaticMarkup } from "react-dom/server";
const state = vi.hoisted(() => ({ other: {} as Record<string, string> }));
vi.mock("@/contexts/SettingsContext", () => ({ useSettings: () => ({ providerId: "vibe", config: { other: state.other }, setConfig: () => undefined }) }));
import PrivacySettings, { generatedPrivacyUrls } from "./PrivacySettings";

it("builds the generated LGPD pages under the public API", () => {
  expect(generatedPrivacyUrls("https://appisp.com.br/api", "vibe")).toEqual({
    privacy: "https://appisp.com.br/api/public/providers/vibe/privacidade",
    deletion: "https://appisp.com.br/api/public/providers/vibe/exclusao-de-dados",
  });
});

it("links the generated pages and warns about non-https custom links", () => {
  vi.stubGlobal("window", { location: { protocol: "https:", hostname: "appisp.com.br", origin: "https://appisp.com.br", port: "" } });
  let html = renderToStaticMarkup(<PrivacySettings />);
  expect(html).toContain("/public/providers/vibe/privacidade");
  expect(html).toContain("/public/providers/vibe/exclusao-de-dados");
  state.other = { privacyPolicyUrl: "http://site" };
  html = renderToStaticMarkup(<PrivacySettings />);
  expect(html).toContain("https://");
  expect(html).toContain("o app usa o seu link próprio");
  vi.unstubAllGlobals();
});
