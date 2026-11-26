import { afterEach, describe, expect, it, vi } from "vitest";

function jwt(payload: Record<string, unknown>) {
  const enc = (v: unknown) => Buffer.from(JSON.stringify(v)).toString("base64url");
  return `${enc({ alg: "HS256" })}.${enc(payload)}.sig`;
}
const future = Math.floor(Date.now() / 1000) + 3600;
const oldToken = jwt({ uid: "u1", email: "a@b.c", role: "providerAdmin", providerId: "vibe", exp: future, auth_time: 1 });
const newToken = jwt({ uid: "u1", email: "a@b.c", role: "providerAdmin", providerId: "vibe", exp: future, auth_time: 2 });

async function freshSession() {
  vi.resetModules();
  const session = await import("./session");
  vi.stubGlobal("fetch", vi.fn(async () => new Response(JSON.stringify({ token: oldToken }), { status: 200 })));
  await session.loginWithEmailPassword("a@b.c", "x");
  return session;
}

afterEach(() => vi.unstubAllGlobals());

describe("changeOwnPassword", () => {
  it("keeps the session with the token returned by the server", async () => {
    const session = await freshSession();
    const fetcher = vi.fn(async () => new Response(JSON.stringify({ ok: true, token: newToken }), { status: 200 }));
    vi.stubGlobal("fetch", fetcher);
    await expect(session.changeOwnPassword("Old123456789", "New123456789")).resolves.toEqual({ relogin: false });
    const [url, init] = fetcher.mock.calls[0] as unknown as [string, RequestInit];
    expect(url).toMatch(/\/admin\/auth\/password$/);
    expect(JSON.parse(String(init.body))).toEqual({ currentPassword: "Old123456789", newPassword: "New123456789" });
    expect(await session.getAccessToken()).toBe(newToken);
  });

  it("asks to log in again when no new token comes back", async () => {
    const session = await freshSession();
    vi.stubGlobal("fetch", vi.fn(async () => new Response(JSON.stringify({ ok: true }), { status: 200 })));
    await expect(session.changeOwnPassword("Old123456789", "New123456789")).resolves.toEqual({ relogin: true });
    expect(session.getCurrentUser()).toBeNull();
  });

  it("reports a wrong current password and a missing route clearly", async () => {
    const session = await freshSession();
    vi.stubGlobal("fetch", vi.fn(async () => new Response(JSON.stringify({ error: { message: "Senha atual incorreta." } }), { status: 401 })));
    await expect(session.changeOwnPassword("bad", "New123456789")).rejects.toThrow("Senha atual incorreta.");
    vi.stubGlobal("fetch", vi.fn(async () => new Response("", { status: 404 })));
    await expect(session.changeOwnPassword("Old123456789", "New123456789")).rejects.toThrow(/suporte da plataforma/);
    expect(session.getCurrentUser()).not.toBeNull();
  });
});
