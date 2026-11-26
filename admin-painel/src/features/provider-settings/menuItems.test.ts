import { describe, expect, it } from "vitest";
import { buildMenuItems, serializeMenuItems } from "./menuItems";
import { toFirestoreProviderConfig, fromFirestoreProviderConfig } from "./normalizers";
import { DEFAULT_PROVIDER_CONFIG } from "./defaults";

describe("menus editor", () => {
  it("does not crash with the default `items: {}` that every provider has", () => {
    const items = buildMenuItems({ order: ["invoices", "support", "contract"], items: {} });
    expect(items.slice(0, 3).map((i) => i.id)).toEqual(["invoices", "support", "contract"]);
    expect(items.every((i) => i.enabled === true && typeof i.color === "string" && i.name)).toBe(true);
    expect(items).toHaveLength(8);
  });

  it("round-trips through the strict config boundary without undefined fields", () => {
    const loaded = fromFirestoreProviderConfig({});
    const items = buildMenuItems(loaded.menuConfig);
    items[0].enabled = false;
    const menuConfig = serializeMenuItems(items);
    const { publicConfig } = toFirestoreProviderConfig({ ...DEFAULT_PROVIDER_CONFIG, menuConfig });
    expect((publicConfig.menuConfig as any).items.invoices).toEqual({ name: "Faturas", type: "internal", enabled: false, color: "#1E6FF8" });
  });

  it("keeps custom links and drops unknown internal ids", () => {
    const items = buildMenuItems({
      order: ["external_1", "unknown", "invoices"],
      items: { external_1: { name: "Site", type: "external_link", url: "https://x.example", enabled: true } as any, invoices: { enabled: false } as any },
    });
    expect(items[0]).toMatchObject({ id: "external_1", type: "external_link", url: "https://x.example" });
    expect(items.find((i) => i.id === "unknown")).toBeUndefined();
    expect(items.find((i) => i.id === "invoices")?.enabled).toBe(false);
    const { publicConfig } = toFirestoreProviderConfig({ ...DEFAULT_PROVIDER_CONFIG, menuConfig: serializeMenuItems(items) });
    expect((publicConfig.menuConfig as any).items.external_1.url).toBe("https://x.example");
  });
});
