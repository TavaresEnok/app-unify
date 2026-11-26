import React from "react";
import { renderToStaticMarkup } from "react-dom/server";
import { expect, it, vi } from "vitest";
const state = vi.hoisted(() => ({ role: "providerAdmin" }));
vi.mock("@/contexts/AuthContext", () => ({ useAuth: () => ({ userRole: state.role }) }));
vi.mock("@/contexts/SettingsContext", () => ({ useSettings: () => ({ providerId: "a", config: { integrations: { apiToken: "stored-private" } } }) }));
vi.mock("@/shared/auth/session", () => ({ auth: {} }));
import IntegrationsSettings from "./IntegrationsSettings";
import { SETTINGS_NAVIGATION } from "@/app/navigation";
it("provider has no integration form or navigation; SaaS gets blank replacement", () => {
 const provider = renderToStaticMarkup(React.createElement(IntegrationsSettings));
 expect(provider).not.toContain("<input");
 expect(SETTINGS_NAVIGATION.find(item => item.path === "integrations")?.superAdminOnly).toBe(true);
 state.role = "superAdmin";
 const saas = renderToStaticMarkup(React.createElement(IntegrationsSettings));
 expect(saas).toContain('type="password"');
 expect(saas).not.toContain("stored-private");
 expect(saas).toContain('value=""');
});
import { integrationErrorMessage } from "./IntegrationsSettings";
it("shows the server reason when replacing the ERP integration fails", () => {
 expect(integrationErrorMessage({ error: { message: "Autentique-se novamente para substituir a integração." } }, 403)).toBe("Autentique-se novamente para substituir a integração.");
 expect(integrationErrorMessage({ error: "Destino SGP inválido ou interno." }, 400)).toBe("Destino SGP inválido ou interno.");
 expect(integrationErrorMessage({}, 500)).toBe("Não foi possível substituir a integração.");
});
