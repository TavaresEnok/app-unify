import { beforeEach, expect, it, vi } from "vitest";

const calls = vi.hoisted(() => [] as Array<{ url: string; headers: Record<string, string> }>);
vi.mock("axios", () => {
  const post = async (url: string, _body: unknown, config: { headers: Record<string, string> }) => {
    calls.push({ url, headers: config.headers });
    return { status: 200, data: { ok: true } };
  };
  return { default: { post, isAxiosError: () => false } };
});

const { proxyToSgp } = await import("./proxySgpClient");

beforeEach(() => { calls.length = 0; });

it("forwards the real subscriber IP so the proxy limits per client", async () => {
  await proxyToSgp("/check-cpf", { cpf: "1" }, undefined, "200.1.2.3");
  await proxyToSgp("/check-cpf", { cpf: "1" }, undefined, "2804:14c::1");
  expect(calls.map((c) => c.headers["X-Forwarded-For"])).toEqual(["200.1.2.3", "2804:14c::1"]);
});

it("never forwards a malformed IP header", async () => {
  await proxyToSgp("/check-cpf", {}, undefined, "1.2.3.4, evil");
  await proxyToSgp("/check-cpf", {}, undefined, undefined);
  expect(calls.every((c) => !("X-Forwarded-For" in c.headers))).toBe(true);
});
