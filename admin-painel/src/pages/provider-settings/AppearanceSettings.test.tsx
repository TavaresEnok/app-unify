import React from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { expect, it, vi } from "vitest";
import type { ProviderConfig } from "@/shared/contracts";
import { normalizeProviderConfig, toFirestoreProviderConfig } from "@/features/provider-settings/normalizers";
import AppearanceSettings from "./AppearanceSettings";

const state = vi.hoisted(() => ({
  config: {} as ProviderConfig,
  inputs: [] as any[], selects: [] as any[], buttons: [] as any[],
  saved: vi.fn(),
}));
vi.mock("@/contexts/SettingsContext", () => ({
  useSettings: () => ({
    config: state.config, isSaving: false,
    setConfig: (update: (previous: ProviderConfig) => ProviderConfig) => { state.config = update(state.config); },
    saveConfig: async () => { state.saved(toFirestoreProviderConfig(state.config).publicConfig); },
  }),
}));
vi.mock("@/components/ui/input", () => ({ Input: (props: any) => { state.inputs.push(props); return null; } }));
vi.mock("@/components/ui/button", () => ({ Button: (props: any) => { state.buttons.push(props); return null; } }));
vi.mock("@/components/ui/select", () => ({
  Select: (props: any) => { state.selects.push(props); return null; },
  SelectContent: () => null, SelectItem: () => null, SelectTrigger: () => null, SelectValue: () => null,
}));

function render() {
  state.inputs = []; state.selects = []; state.buttons = [];
  return renderToStaticMarkup(<AppearanceSettings />);
}
function select(layout: string) {
  render();
  state.selects[0].onValueChange(layout);
}
function changeColor(color: string) {
  render();
  state.inputs[0].onChange({ target: { value: color } });
}

it("shows the official thumbnail for each identifier and the selected palette", () => {
  state.config = normalizeProviderConfig({ layoutType: "layout_03", themeColor: "#fc46aa" });
  const html = render();
  for (const id of ["02", "03", "04", "05", "06"]) {
    expect(html).toContain(`/assets/layout-previews/preview-${id}-${id === "03" ? "rosa" : "azul"}-light.webp`);
  }
  expect(html).toContain("Prévia de Dock de serviços no modo claro");
  expect(state.inputs).toHaveLength(1);
});

it("keeps legacy overrides and saves only the active layout's brand when switching or restoring", () => {
  const legacy = { themeColor: "#abcdef" };
  const themes = {
    layout_01: legacy,
    layout_06: { iconColor: "#123abc", themeColor: "#765432" },
    layout_03: { actionColor: "#654321", themeColor: "#137650" },
  };
  state.config = normalizeProviderConfig({
    layoutType: "layout_06", themeColor: "#765432", backgroundColor: "#abcdef", actionColor: "#765432",
    strings: { hello_prefix: "Olá", layoutThemes: JSON.stringify(themes) },
  });
  changeColor("#123456");
  select("layout_03");
  expect(state.config.themeColor).toBe("#137650");
  select("layout_06");
  expect(state.config.themeColor).toBe("#123456");
  render();
  state.buttons.find(button => button.disabled === false).onClick();
  const payload = state.saved.mock.lastCall![0];
  expect(normalizeProviderConfig(payload).themeColor).toBe("#123456");
  expect(JSON.parse(payload.strings.layoutThemes)).toMatchObject({
    layout_01: legacy, layout_06: { ...themes.layout_06, themeColor: "#123456" }, layout_03: themes.layout_03,
  });
  state.buttons[0].onClick();
  expect(state.config).toMatchObject({ themeColor: "#2456C9", backgroundColor: "#abcdef", actionColor: "#765432" });
  expect(state.config.strings?.hello_prefix).toBe("Olá");
  expect(JSON.parse(state.config.strings!.layoutThemes!)).toEqual({
    ...themes, layout_06: { ...themes.layout_06, themeColor: "#2456C9" },
  });
});

it("does not put a partially typed color in settings", () => {
  state.config = normalizeProviderConfig({ layoutType: "layout_02", themeColor: "#123456" });
  changeColor("#12");
  expect(state.config.themeColor).toBe("#123456");
});

it("recovers from malformed legacy palettes", () => {
  state.config = normalizeProviderConfig({ layoutType: "layout_02", themeColor: "#123456",
    strings: { layoutThemes: "{broken", hello_prefix: "Olá" } });
  select("layout_03");
  expect(state.config.themeColor).toBe("#2456C9");
  expect(state.config.strings?.hello_prefix).toBe("Olá");
  expect(JSON.parse(state.config.strings!.layoutThemes!).layout_02.themeColor).toBe("#123456");
});

it.each(["layout_01", "legacy_unknown", ""])("preserves existing identifier %s until another design is selected", legacy => {
  state.config = { ...normalizeProviderConfig({ layoutType: "layout_06", themeColor: "#123456" }), layoutType: legacy as ProviderConfig["layoutType"],
    strings: { layoutThemes: JSON.stringify({ layout_01: { themeColor: "#abcdef" } }) } };
  select("layout_06");
  expect(state.config.layoutType).toBe(legacy);
  changeColor("#FC46AA");
  expect(state.config.layoutType).toBe(legacy);
  select("layout_02");
  const themes = JSON.parse(state.config.strings!.layoutThemes!);
  expect(themes.layout_01.themeColor).toBe("#abcdef");
  expect(themes.layout_06.themeColor).toBe("#FC46AA");
  select("layout_06");
  expect(state.config.themeColor).toBe("#FC46AA");
});
