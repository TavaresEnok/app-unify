import { expect, it, vi } from "vitest";
const add = vi.hoisted(() => vi.fn().mockResolvedValue(undefined));
vi.mock("./firebaseAdmin", () => ({ firestore: { collection: () => ({ add }) }, serverTimestamp: () => "now" }));
import { recordAdminAudit } from "./auditService";
it("provider audit retains metadata without raw config or private replacement values", async () => {
  for (const type of ["CREATE_PROVIDER", "UPDATE_PROVIDER", "REPLACE_PROVIDER_INTEGRATION"]) {
    await recordAdminAudit({ type, requesterUid: "saas", providerId: "a", payload: {
      themeColor: "synthetic-private-disguised-as-text", integrations: { apiToken: "synthetic-private" },
      details: { systemUrl: "synthetic-private", secretRef: "synthetic-private" },
    } });
  }
  for (const [entry] of add.mock.calls) {
    expect(entry.payload).toEqual({ configurationChanged: true });
    expect(JSON.stringify(entry)).not.toContain("synthetic-private");
  }
});
