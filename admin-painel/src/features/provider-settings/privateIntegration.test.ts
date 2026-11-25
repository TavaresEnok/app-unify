import { describe, expect, it } from "vitest";
import { parsePrivateIntegration } from "./configBoundary";

describe("parsePrivateIntegration", () => {
  const base = { apiToken: "t", sgpBaseUrl: "https://erp.example.com" };

  it("mantém o formato legado do SGP (sem campo erp)", () => {
    expect(parsePrivateIntegration({ ...base, appName: "app" })).toEqual({ ...base, appName: "app" });
    expect(parsePrivateIntegration({ ...base, appName: "app", erp: "sgp" })).toEqual({ ...base, appName: "app" });
    expect(() => parsePrivateIntegration(base)).toThrow();
  });

  it("IXC exige só token e URL e descarta o app", () => {
    expect(parsePrivateIntegration({ ...base, erp: "ixc", appName: "ignorado" })).toEqual({ ...base, erp: "ixc" });
    expect(parsePrivateIntegration({ ...base, erp: "IXC" })).toEqual({ ...base, erp: "ixc" });
  });

  it("rejeita ERP desconhecido, URL insegura e campos extras", () => {
    expect(() => parsePrivateIntegration({ ...base, appName: "a", erp: "outro" })).toThrow();
    expect(() => parsePrivateIntegration({ ...base, erp: "ixc", sgpBaseUrl: "http://erp.example.com" })).toThrow();
    expect(() => parsePrivateIntegration({ ...base, erp: "ixc", extra: "x" })).toThrow();
  });
});
