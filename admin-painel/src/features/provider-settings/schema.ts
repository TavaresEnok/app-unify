export interface ProviderSettingSection {
  id: string;
  fields: readonly string[];
}

export const PROVIDER_SETTING_SECTIONS: readonly ProviderSettingSection[] = [
  { id: "appearance", fields: ["layoutType", "diagnosticStyle", "themeColor", "secondaryColor", "backgroundColor", "cardColor", "cardTextColor", "textColor", "textSecondaryColor", "iconColor", "actionColor", "invoiceColor", "quickActionsCardColor", "quickActionsTextColor", "otherCardsColor", "otherCardsTextColor"] },
  { id: "typography", fields: ["typography"] },
  { id: "images", fields: ["logoUrl", "iconUrl", "backgroundUrl"] },
  { id: "menus", fields: ["menuConfig"] },
  { id: "dashboard", fields: ["dashboardConfig", "dashboard"] },
  { id: "carousel", fields: ["imageCarousel"] },
  { id: "promotions", fields: ["promotions"] },
  { id: "notifications", fields: ["notifications"] },
  { id: "tips", fields: ["tips"] },
  { id: "faq", fields: ["faq"] },
  { id: "messages", fields: ["messages"] },
  { id: "texts", fields: ["strings", "loginQuote", "termsOfUse"] },
  { id: "features", fields: ["features"] },
  { id: "integrations", fields: ["integrations"] },
  { id: "support", fields: ["supportContacts", "supportChannels"] },
  { id: "social", fields: ["social", "socialNetworks"] },
  { id: "other", fields: ["other", "appVersion", "splash", "login"] },
] as const;

const knownFields = new Set(PROVIDER_SETTING_SECTIONS.flatMap((section) => [...section.fields]));

export function getUnknownProviderConfigFields(config: Record<string, unknown>): string[] {
  const metadata = new Set(["id", "name", "active", "details", "createdAt", "updatedAt", "config"]);
  return Object.keys(config).filter((key) => !knownFields.has(key) && !metadata.has(key));
}
