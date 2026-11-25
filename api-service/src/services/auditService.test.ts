import { expect, it, vi } from "vitest";
const query = vi.hoisted(() => vi.fn().mockResolvedValue({ rows: [] }));
vi.mock("./postgres", () => ({
  getPgPool: () => ({ query }),
  ensureCoreSchema: async () => undefined,
}));
import { recordAdminAudit } from "./auditService";

it("provider audit retains metadata without raw config or private replacement values", async () => {
  for (const type of ["CREATE_PROVIDER", "UPDATE_PROVIDER", "REPLACE_PROVIDER_INTEGRATION"]) {
    await recordAdminAudit({
      type,
      requesterUid: "saas",
      providerId: "a",
      payload: {
        themeColor: "synthetic-private-disguised-as-text",
        integrations: { apiToken: "synthetic-private" },
        details: { systemUrl: "synthetic-private", secretRef: "synthetic-private" },
      },
    });
  }
  expect(query).toHaveBeenCalledTimes(3);
  for (const call of query.mock.calls) {
    const params = call[1] as unknown[];
    expect(JSON.parse(String(params[4]))).toEqual({ configurationChanged: true });
    expect(JSON.stringify(params)).not.toContain("synthetic-private");
  }
});
