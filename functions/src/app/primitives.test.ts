const getUser = jest.fn();

jest.mock("./firebase", () => ({
  auth: { getUser },
}));

import { AppError, toAppError } from "./errors";
import {
  isSuperAdmin,
  requesterProviderId,
  requireProviderAccess,
  requireRequester,
  requireSuperAdmin,
} from "./permissions";
import { toRequestContext } from "./request";

const user = (claims: Record<string, unknown> = {}) => ({
  uid: "user-1",
  customClaims: claims,
}) as never;

beforeEach(() => getUser.mockReset());

describe("application errors", () => {
  it("preserves known application errors", () => {
    const error = new AppError("not-found", "ausente");
    expect(toAppError(error)).toBe(error);
  });

  it("normalizes Error and unknown values", () => {
    expect(toAppError(new Error("falhou"))).toMatchObject({ code: "internal", message: "falhou" });
    expect(toAppError(null)).toMatchObject({ code: "internal", message: "Falha interna inesperada." });
  });
});

describe("permission checks", () => {
  it("requires an authenticated requester", async () => {
    await expect(requireRequester("")).rejects.toMatchObject({ code: "unauthenticated" });
    getUser.mockRejectedValueOnce(new Error("missing"));
    await expect(requireRequester("missing")).rejects.toMatchObject({ code: "unauthenticated" });
  });

  it("returns the requester record", async () => {
    const record = user();
    getUser.mockResolvedValueOnce(record);
    await expect(requireRequester("user-1")).resolves.toBe(record);
  });

  it("reads claims without coercing invalid provider identifiers", () => {
    expect(isSuperAdmin(user({ superAdmin: true }))).toBe(true);
    expect(isSuperAdmin(user({ superAdmin: "true" }))).toBe(false);
    expect(requesterProviderId(user({ providerId: "provider-1" }))).toBe("provider-1");
    expect(requesterProviderId(user({ providerId: 123 }))).toBeUndefined();
  });

  it("restricts super admin operations", async () => {
    getUser.mockResolvedValueOnce(user());
    await expect(requireSuperAdmin("user-1")).rejects.toMatchObject({ code: "permission-denied" });
    const admin = user({ superAdmin: true });
    getUser.mockResolvedValueOnce(admin);
    await expect(requireSuperAdmin("user-1")).resolves.toBe(admin);
  });

  it("allows only the matching provider or a super admin", async () => {
    getUser.mockResolvedValueOnce(user({ providerId: "provider-1" }));
    await expect(requireProviderAccess("user-1", "provider-1")).resolves.toBeDefined();
    getUser.mockResolvedValueOnce(user({ providerId: "provider-2" }));
    await expect(requireProviderAccess("user-1", "provider-1")).rejects.toMatchObject({ code: "permission-denied" });
    getUser.mockResolvedValueOnce(user({ superAdmin: true }));
    await expect(requireProviderAccess("user-1", "provider-1")).resolves.toBeDefined();
  });
});

test("toRequestContext preserves the typed request envelope", () => {
  const request = {
    type: "GET_DASHBOARD" as const,
    requesterUid: "user-1",
    payload: { providerId: "provider-1" },
  };
  expect(toRequestContext("request-1", request)).toEqual({ requestId: "request-1", ...request });
});
