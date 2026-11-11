import { expect, it, vi } from "vitest";
import { renderToStaticMarkup } from "react-dom/server";
import { MemoryRouter, Route, Routes } from "react-router-dom";
const session = vi.hoisted(() => ({ userRole: "providerAdmin", providerId: "alpha" }));
vi.mock("@/contexts/AuthContext", () => ({ useAuth: () => session }));
import ProviderSettingsLayout from "./ProviderSettingsLayout";

function render(path: string, role = "providerAdmin") {
  session.userRole = role;
  return renderToStaticMarkup(<MemoryRouter initialEntries={[path]}><Routes>
    <Route path="/provedor/personalizacao" element={<ProviderSettingsLayout />}><Route path=":page" element={<p>Editor</p>} /></Route>
    <Route path="/provedores/:providerId" element={<ProviderSettingsLayout />}><Route path=":page" element={<p>Editor</p>} /></Route>
  </Routes></MemoryRouter>);
}

it("groups provider editors into five areas without exposing SaaS operations", () => {
  const html = render("/provedor/personalizacao/typography");
  expect(html).toContain("Identidade visual");
  expect(html).toContain("Tela inicial e navegação");
  expect(html).toContain("Contato e informações legais");
  expect(html).toContain('href="/provedor/personalizacao/splash-login"');
  expect(html).not.toContain("Operação técnica");
  expect(html).not.toContain("/integrations");
  expect(html).not.toContain("/app-build");
});

it("keeps SaaS operations scoped to the provider selected in the route", () => {
  const html = render("/provedores/beta/integrations", "superAdmin");
  expect(html).toContain("Operação técnica");
  expect(html).toContain('href="/provedores/beta/app-build"');
  expect(html).not.toContain("/provedores/alpha/");
});
