import { expect, it } from "vitest";
import { newProviderIdError, normalizeProviderId } from "./providerId";

it("blocks invalid and existing provider ids", () => {
  expect(newProviderIdError("", [])).toMatch(/Informe/);
  expect(newProviderIdError("meu provedor", [])).toMatch(/letras minúsculas/);
  expect(newProviderIdError("vibe", ["vibe", "insnet"])).toBe("Já existe um provedor com este ID.");
  expect(newProviderIdError(normalizeProviderId("  NovaNet "), ["vibe"])).toBeNull();
});
