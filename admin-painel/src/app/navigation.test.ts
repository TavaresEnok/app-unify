import { describe, expect, it } from "vitest";
import {
  PROVIDER_NAVIGATION,
  SETTINGS_GROUPS,
  SETTINGS_NAVIGATION,
  SUPER_ADMIN_NAVIGATION,
  titleForPath,
} from "./navigation";

describe("navigation registry", () => {
  it("does not contain duplicate routes", () => {
    const routes = [...PROVIDER_NAVIGATION, ...SUPER_ADMIN_NAVIGATION].map((item) => item.to);
    expect(new Set(routes).size).toBe(routes.length);
  });

  it("places every settings page in a group", () => {
    const grouped = new Set(SETTINGS_GROUPS.flatMap((group) => [...group.items]));
    expect(SETTINGS_NAVIGATION.every((item) => grouped.has(item.path as any))).toBe(true);
  });

  it("uses the closest route title", () => {
    expect(titleForPath("/provedor/clientes/123", true)).toBe("Cliente");
    expect(titleForPath("/provedores/acme/appearance", false)).toBe("Configuração do provedor");
  });
});
