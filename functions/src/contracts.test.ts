import {
  FUNCTION_REQUEST_TYPES,
  assertFunctionRequest,
  isFunctionRequestType,
  requireString,
  validateFunctionPayload,
} from "./contracts";

describe("shared function request contracts", () => {
  it("keeps request names unique", () => {
    expect(new Set(FUNCTION_REQUEST_TYPES).size).toBe(FUNCTION_REQUEST_TYPES.length);
  });

  it("validates a request envelope", () => {
    expect(() => assertFunctionRequest({
      type: "GET_DASHBOARD_DATA",
      requesterUid: "uid-1",
      payload: {},
    })).not.toThrow();
  });

  it("rejects unknown request names", () => {
    expect(isFunctionRequestType("DOES_NOT_EXIST")).toBe(false);
    expect(() => assertFunctionRequest({
      type: "DOES_NOT_EXIST",
      requesterUid: "uid-1",
      payload: {},
    })).toThrow("Tipo de requisicao invalido");
  });

  it("normalizes required strings", () => {
    expect(requireString("  Unify  ", "name")).toBe("Unify");
    expect(() => requireString("", "name")).toThrow();
  });

  it("rejects missing and invalid domain payload fields", () => {
    expect(() => validateFunctionPayload("CREATE_TICKET", { providerId: "alpha" })).toThrow("payload.subject");
    expect(() => validateFunctionPayload("SGP_API_PROXY", { providerId: "alpha", action: "remove" })).toThrow("payload.action");
  });
});
