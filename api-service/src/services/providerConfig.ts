// Canonical source: shared/runtime/providerConfig.ts; mirrored for standalone deploys.
type Shape = "string" | "boolean" | "number" | "layoutThemes" | { [key: string]: Shape } | readonly [Shape];
const strings = (keys: string): Record<string, Shape> => Object.fromEntries(keys.split(" ").map(k => [k, "string"]));
const booleans = (keys: string): Record<string, Shape> => Object.fromEntries(keys.split(" ").map(k => [k, "boolean"]));
// Legacy clients store per-layout themes as JSON text. Validate its contents,
// rather than admitting arbitrary JSON or treating the encoded map as opaque.
const layoutThemeSchema: Shape = Object.fromEntries(
  "layout_01 layout_02 layout_03 layout_04 layout_05 layout_06".split(" ").map(key => [
    key, strings("themeColor secondaryColor actionColor invoiceColor cardColor textColor backgroundColor iconColor quickActionsCardColor quickActionsTextColor otherCardsColor otherCardsTextColor"),
  ]),
);
const menuItem: Shape = { enabled: "boolean", name: "string", icon: "string", type: "string", url: "string", color: "string" };
const menuKeys = "invoices support contract consumption diagnostics notifications profile home speedtest speedTest plans tips faq logout financial tickets services payment_promise speed_test internet_usage my_ip";
const dashboard: Shape = { widgets: [{ ...strings("id type title size color icon"), enabled: "boolean", order: "number", position: "number", visible: "boolean", config: { ...booleans("showInvoice showConnection showPlan showLabels"), ...strings("imageUrl chartType"), height: "number", borderRadius: "number", columns: "number", iconSize: "number", period: "number", actions: ["string"] } }] };
export const personalizationSchema: Record<string, Shape> = {
  ...strings("layoutType diagnosticStyle themeColor secondaryColor backgroundColor cardColor cardTextColor textColor textSecondaryColor iconColor actionColor invoiceColor quickActionsCardColor quickActionsTextColor otherCardsColor otherCardsTextColor logoUrl iconUrl backgroundUrl loginQuote termsOfUse iconPack"),
  typography: strings("fontFamily titleSize bodySize fontWeight"),
  imageCarousel: ["string"],
  menuConfig: { order: ["string"], items: Object.fromEntries(menuKeys.split(" ").map(k => [k, menuItem]).concat([["$customMenu", menuItem]])) },
  supportContacts: [{ ...strings("id name type value") }],
  supportChannels: [{ ...strings("id name type value title subtitle icon url phone email") }],
  faq: [{ ...strings("id question answer") }],
  tips: [{ ...strings("id title description content icon imageUrl") }],
  strings: { ...strings("hello_prefix plan_prefix logout_label home_tab_title diagnostics_button status_ok_title status_ok_message select_contract_message last_invoice_label view_invoices_label pay_invoice_label promise_payment_label support_title channels_title open_ticket_title terms_title"), ticket_subjects: ["string"], layoutThemes: "layoutThemes" },
  features: booleans("consumption support invoices contract diagnostics speedTest speedtest notifications tickets tips faq plans profile payment_promise speed_test terms_of_use custom_menu"),
  messages: strings("welcome invoiceReminder"),
  social: strings("facebook instagram twitter youtube linkedin whatsapp tiktok website"),
  socialNetworks: strings("facebook instagram twitter youtube linkedin whatsapp tiktok website"),
  other: { ...strings("privacyPolicyUrl customDomain speedTestUrl"), ...booleans("useBackgroundImage showTvService showPhoneService") },
  splash: { ...strings("logoUrl backgroundColor animation progressBarColor"), enabled: "boolean", duration: "number", showProgressBar: "boolean" },
  login: { ...strings("style backgroundType quote backgroundColor backgroundUrl"), showLogo: "boolean" },
  promotions: { enabled: "boolean", items: [{ ...strings("id title description imageUrl link startDate endDate badge status type createdAt"), active: "boolean", showCountdown: "boolean" }] },
  notifications: { list: [{ ...strings("id title message date type category createdAt"), read: "boolean", targetAll: "boolean", dismissible: "boolean", sent: "boolean" }] },
  dashboardConfig: dashboard, dashboard,
};
export const detailsSchema: Record<string, Shape> = strings("name email phone address cnpj contactName commercialName website city state systemType");
const metadataSchema: Record<string, Shape> = {
  ...strings("id name applicationId packageName versionName apkUrl appUrl createdByRequestId"),
  active: "boolean", versionCode: "number",
  details: detailsSchema,
  appVersion: { ...strings("minVersion latestVersion"), forceUpdate: "boolean", storeUrls: strings("android ios"), updateMessage: { pt_BR: strings("title message buttonText") } },
};
function object(value: unknown): value is Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}
function visit(value: unknown, shape: Shape, strict: boolean): unknown {
  if (shape === "layoutThemes") {
    if (typeof value !== "string") {
      if (strict) throw new Error("Tipo de configuração inválido.");
      return undefined;
    }
    let decoded: unknown;
    try { decoded = JSON.parse(value); } catch {
      if (strict) throw new Error("Tema de layout inválido.");
      return undefined;
    }
    const themes = visit(decoded, layoutThemeSchema, strict);
    return themes === undefined ? undefined : JSON.stringify(themes);
  }
  if (typeof shape === "string") {
    if (typeof value === shape && (shape !== "number" || Number.isFinite(value))) return value;
  } else if (Array.isArray(shape)) {
    if (Array.isArray(value)) {
      return value.map(v => visit(v, shape[0], strict)).filter(v => v !== undefined);
    }
  } else if (object(value)) {
    const out: Record<string, unknown> = {};
    for (const [key, v] of Object.entries(value)) {
      const fieldShape = Object.prototype.hasOwnProperty.call(shape, key) ? (shape as Record<string, Shape>)[key] : /^(custom|external)_[0-9]+$/.test(key) ? (shape as Record<string, Shape>).$customMenu : undefined;
      if (!fieldShape || key === "$customMenu") {
        if (strict) throw new Error("Campo de configuração não permitido.");
        continue;
      }
      const next = visit(v, fieldShape, strict);
      if (next !== undefined) out[key] = next;
    }
    return out;
  }
  if (strict) throw new Error("Tipo de configuração inválido.");
  return undefined;
}
export function parsePersonalization(value: unknown): Record<string, unknown> {
  const parsed = visit(value, personalizationSchema, true);
  if (!object(parsed)) throw new Error("Configuração inválida.");
  return parsed;
}
export function parseDetails(value: unknown): Record<string, unknown> {
  const parsed = visit(value, detailsSchema, true);
  if (!object(parsed)) throw new Error("Dados inválidos.");
  return parsed;
}
export function sanitizePersonalization(value: unknown): Record<string, unknown> {
  if (!object(value)) return {};
  const legacy = visit(value.config, personalizationSchema, false) as Record<string, unknown> || {};
  const root = visit(value, personalizationSchema, false) as Record<string, unknown> || {};
  return mergePersonalization(legacy, root);
}
// Both namespaces are sanitized first. Root wins per field; arrays replace
// entirely. Used by normalization, backup and restore without merging defaults.
function mergePersonalization(base: Record<string, unknown>, next: Record<string, unknown>): Record<string, unknown> {
  const result = { ...base };
  for (const [key, value] of Object.entries(next)) {
    result[key] = object(result[key]) && object(value)
      ? mergePersonalization(result[key] as Record<string, unknown>, value)
      : value;
  }
  return result;
}
export function publicProviderData(value: Record<string, unknown>): Record<string, unknown> {
  const result = visit(value, { ...personalizationSchema, ...metadataSchema, config: personalizationSchema }, false) as Record<string, unknown>;
  for (const key of ["createdAt", "updatedAt"]) {
    const date = value[key];
    if (typeof date === "string") result[key] = date;
    else if (object(date) && typeof date.toDate === "function") result[key] = date.toDate().toISOString();
  }
  return result;
}
export function parseProviderInput(value: unknown, admin: boolean): Record<string, unknown> {
  const parsed = visit(value, admin ? { ...personalizationSchema, name: "string", active: "boolean", details: detailsSchema, config: personalizationSchema } : personalizationSchema, true);
  if (!object(parsed)) throw new Error("Configuração inválida.");
  return parsed;
}
// Replaces only the personalization namespace. No merge resurrects fields absent in a backup.
export function restoredPersonalization(current: Record<string, unknown>, backup: unknown): Record<string, unknown> {
  const result = { ...current };
  for (const key of Object.keys(personalizationSchema)) delete result[key];
  if (object(result.config)) {
    const legacy = { ...result.config };
    for (const key of Object.keys(personalizationSchema)) delete legacy[key];
    result.config = legacy;
  }
  return { ...result, ...sanitizePersonalization(backup) };
}
export function parsePrivateIntegration(value: unknown): Record<string, string> {
  const parsed = visit(value, strings("apiToken sgpBaseUrl appName"), true) as Record<string, string>;
  if (!object(parsed) || !parsed.apiToken?.trim() || !parsed.appName?.trim() || !parsed.sgpBaseUrl) throw new Error("Integração incompleta.");
  const url = new URL(parsed.sgpBaseUrl);
  if (url.protocol !== "https:" || url.username || url.password || url.search || url.hash) throw new Error("Destino de integração inválido.");
  return parsed;
}

