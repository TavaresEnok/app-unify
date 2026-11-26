import type { MenuConfig } from "@/shared/contracts";

export interface MenuItem {
  id: string;
  name: string;
  type: "internal" | "external_link";
  url?: string;
  color: string;
  enabled: boolean;
}

export const DEFAULT_MENU_COLOR = "#673AB7";

export const DEFAULT_MENU_ITEMS: Omit<MenuItem, "enabled">[] = [
  { id: "notifications", name: "Notificações", type: "internal", color: "#F59E0B" },
  { id: "invoices", name: "Faturas", type: "internal", color: "#1E6FF8" },
  { id: "payment_promise", name: "Promessa de Pagamento", type: "internal", color: "#10B981" },
  { id: "speed_test", name: "Teste de Velocidade", type: "internal", color: "#8B5CF6" },
  { id: "internet_usage", name: "Consumo de Internet", type: "internal", color: "#EC4899" },
  { id: "support", name: "Suporte", type: "internal", color: "#06B6D4" },
  { id: "contract", name: "Contrato", type: "internal", color: "#6366F1" },
  { id: "my_ip", name: "Meu IP", type: "internal", color: "#F97316" },
];

const nonEmpty = (value: unknown): string | undefined =>
  typeof value === "string" && value.trim() ? value : undefined;

/**
 * Monta a lista editável a partir do menuConfig salvo. Tolera `items` vazio ou
 * itens ausentes (o padrão de todos os provedores é `{order:[...], items:{}}`)
 * e sempre devolve campos definidos, porque a validação estrita do painel
 * recusa booleanos/strings `undefined` ao salvar.
 */
export function buildMenuItems(saved: Partial<MenuConfig> | null | undefined): MenuItem[] {
  const order = Array.isArray(saved?.order) ? saved!.order.filter((id): id is string => typeof id === "string" && Boolean(id)) : [];
  const items = saved?.items && typeof saved.items === "object" ? saved.items as Record<string, Partial<MenuItem> | undefined> : {};
  const seen = new Set<string>();
  const result: MenuItem[] = [];
  for (const id of order) {
    if (seen.has(id)) continue;
    const savedItem = items[id] ?? {};
    const defaultItem = DEFAULT_MENU_ITEMS.find((d) => d.id === id);
    const type: MenuItem["type"] = savedItem.type === "external_link" || savedItem.type === "internal"
      ? savedItem.type
      : defaultItem?.type || "internal";
    if (!defaultItem && type !== "external_link") continue;
    const url = nonEmpty(savedItem.url);
    if (type === "external_link" && !url) continue;
    seen.add(id);
    result.push({
      id,
      name: nonEmpty(savedItem.name) || defaultItem?.name || "Item",
      type,
      ...(type === "external_link" ? { url } : {}),
      color: nonEmpty(savedItem.color) || defaultItem?.color || DEFAULT_MENU_COLOR,
      enabled: typeof savedItem.enabled === "boolean" ? savedItem.enabled : true,
    });
  }
  for (const defaultItem of DEFAULT_MENU_ITEMS) {
    if (!seen.has(defaultItem.id)) result.push({ ...defaultItem, enabled: true });
  }
  return result;
}

export function serializeMenuItems(items: MenuItem[]): MenuConfig {
  return {
    order: items.map((item) => item.id),
    items: Object.fromEntries(items.map((item) => [item.id, {
      name: item.name || "Item",
      type: item.type,
      enabled: item.enabled !== false,
      color: item.color || DEFAULT_MENU_COLOR,
      ...(item.type === "external_link" && item.url ? { url: item.url } : {}),
    }])) as MenuConfig["items"],
  };
}
