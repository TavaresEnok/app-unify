import { expect, it } from "vitest";
import { companyDetailsFromProvider, companyDetailsPayload } from "./companyDetails";
import { parseDetails, publicProviderData } from "./configBoundary";

it("keeps the migrated company fields visible and savable", () => {
  const provider = publicProviderData({ id: "vibe", details: { razaoSocial: "Vibe LTDA", nomeFantasia: "Vibe", telefone: "11999990000", cnpj: "00.000.000/0001-00" } });
  const details = companyDetailsFromProvider(provider.details);
  expect(details).toMatchObject({ razaoSocial: "Vibe LTDA", nomeFantasia: "Vibe", telefone: "11999990000" });
  expect(() => parseDetails(companyDetailsPayload(details))).not.toThrow();
});

it("falls back to commercialName/phone and trims the payload", () => {
  const details = companyDetailsFromProvider({ commercialName: "Net X", phone: "1133334444" });
  expect(details.nomeFantasia).toBe("Net X");
  expect(details.telefone).toBe("1133334444");
  expect(companyDetailsPayload({ razaoSocial: "  A  ", email: undefined })).toEqual({ razaoSocial: "A" });
});
