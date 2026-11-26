import { expect, it } from "vitest";
import { canOpenAfterLogin, loginPathWithNext, safeNextPath } from "./loginRedirect";

it("accepts only internal panel paths as next", () => {
  expect(safeNextPath("/provedor/clientes?search=ana")).toBe("/provedor/clientes?search=ana");
  expect(safeNextPath("//evil.example")).toBeNull();
  expect(safeNextPath("https://evil.example")).toBeNull();
  expect(safeNextPath("/\\evil.example")).toBeNull();
  expect(safeNextPath("/login?next=/x")).toBeNull();
  expect(safeNextPath(null)).toBeNull();
});

it("builds the login url keeping the current screen", () => {
  expect(loginPathWithNext("/provedor/personalizacao/faq", "?a=1")).toBe(`/login?next=${encodeURIComponent("/provedor/personalizacao/faq?a=1")}`);
  expect(loginPathWithNext("/login")).toBe("/login");
});

it("keeps each role inside its own area after login", () => {
  expect(canOpenAfterLogin("/provedor/clientes", "providerAdmin")).toBe(true);
  expect(canOpenAfterLogin("/provedores/vibe/appearance", "providerAdmin")).toBe(false);
  expect(canOpenAfterLogin("/conta/senha", "providerAdmin")).toBe(true);
  expect(canOpenAfterLogin("/provedores/vibe/clientes", "superAdmin")).toBe(true);
  expect(canOpenAfterLogin("/provedor/dashboard", "superAdmin")).toBe(false);
});
