import React from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { expect, it, vi } from "vitest";
import type { ProviderConfig } from "@/shared/contracts";

const state = vi.hoisted(() => ({
 config: {} as ProviderConfig,
 inputs: [] as any[], selects: [] as any[], buttons: [] as any[],
 rpc: vi.fn(), pendingSave: undefined as Promise<void> | undefined,
}));
vi.mock("@/features/providers/providerService", () => ({ subscribeProvider: vi.fn() }));
vi.mock("@/firebase/config", () => ({ db: {}, auth: { currentUser: { uid: "provider" } } }));
vi.mock("@/shared/api/functionRequests", () => ({ callFunctionRequest: state.rpc }));
vi.mock("@/contexts/SettingsContext", () => ({
 useSettings: () => ({
  config: state.config, isSaving: false,
  setConfig: (update: (previous: ProviderConfig) => ProviderConfig) => { state.config = update(state.config); },
  saveConfig: () => { state.pendingSave = saveProviderSettings("a", state.config); return state.pendingSave; },
 }),
}));
// Capture event callbacks at UI primitives; the page handlers and the entire
// save/normalization/serialization path remain real.
vi.mock("@/components/ui/input", () => ({ Input: (props: any) => { state.inputs.push(props); return null; } }));
vi.mock("@/components/ui/button", () => ({ Button: (props: any) => { state.buttons.push(props); return null; } }));
vi.mock("@/components/ui/select", () => ({
 Select: (props: any) => { state.selects.push(props); return null; },
 SelectContent: () => null, SelectItem: () => null, SelectTrigger: () => null, SelectValue: () => null,
}));

import AppearanceSettings from "./AppearanceSettings";
import { saveProviderSettings } from "@/shared/firebase/providerSettingsService";
import { normalizeProviderConfig } from "@/features/provider-settings/normalizers";

function render() {
 state.inputs = []; state.selects = []; state.buttons = [];
 renderToStaticMarkup(<AppearanceSettings />);
}

it("saves real color, layout switching and reset handlers with validated per-layout themes", async () => {
 state.rpc.mockReset();
 state.config = normalizeProviderConfig({
  layoutType: "layout_06",
  config: { strings: { hello_prefix: "Legado" }, typography: { fontFamily: "Inter" } },
  strings: { plan_prefix: "Plano", layoutThemes: JSON.stringify({ layout_01: { themeColor: "#abcdef" } }) },
  typography: { bodySize: "large" },
 });
 expect(state.config.strings).toMatchObject({ hello_prefix: "Legado", plan_prefix: "Plano" });
 expect(state.config.typography).toMatchObject({ fontFamily: "Inter", bodySize: "large" });
 render();
 state.inputs[0].onChange({ target: { value: "#123456" } });
 render();
 state.selects[0].onValueChange("layout_01");
 expect(state.config.themeColor).toBe("#abcdef");
 render();
 state.selects[0].onValueChange("layout_06");
 expect(state.config.themeColor).toBe("#123456");
 render();
 state.buttons[state.buttons.length - 1].onClick();
 await state.pendingSave;
 const payload = state.rpc.mock.calls[0][2].config;
 expect(payload.themeColor).toBe("#123456");
 expect(JSON.parse(payload.strings.layoutThemes)).toMatchObject({
  layout_01: { themeColor: "#abcdef" }, layout_06: { themeColor: "#123456" },
 });
 expect(normalizeProviderConfig(payload).strings?.layoutThemes).toBe(payload.strings.layoutThemes);
 render();
 state.buttons[0].onClick(); // Restore the active layout's defaults.
 render();
 state.buttons[state.buttons.length - 1].onClick();
 await state.pendingSave;
 expect(JSON.parse(state.rpc.mock.calls[1][2].config.strings.layoutThemes).layout_06.themeColor).toBe(state.config.themeColor);
 for (const field of ["apiToken", "secretRef", "unknown"]) {
  const invalid = { ...state.config, strings: {
   ...state.config.strings, layoutThemes: JSON.stringify({ layout_06: { themeColor: "#123456", [field]: "synthetic" } }),
  } };
  await expect(saveProviderSettings("a", invalid)).rejects.toThrow();
 }
 expect(state.rpc).toHaveBeenCalledTimes(2);
});
