import { describe, expect, it, vi } from "vitest";
import request from "supertest";
import { createApp } from "./app";

vi.mock('./services/firebaseAdmin', () => ({
  firestore: {}, serverTimestamp: () => null,
  firebaseAuth: { verifyIdToken: async (token: string) => {
    if (token === 'test-root') return { uid: 'root', superAdmin: true };
    if (token === 'test-provider') return { uid: 'provider', role: 'providerAdmin', providerId: 'one' };
    if (token === 'test-sub') return { uid: 'subscriber', role: 'subscriber', providerId: 'one' };
    throw Error('Invalid test token');
  } },
}));

describe("api app", () => {
  const app = createApp();

  it("exposes a health check", async () => {
    const response = await request(app).get("/health").expect(200);
    expect(response.body.status).toBe("ok");
    expect(response.headers["x-correlation-id"]).toBeTruthy();
  });

  it("returns the standard error envelope for unknown routes", async () => {
    const response = await request(app).get("/missing").expect(404);
    expect(response.body.error.code).toBe("not-found");
    expect(response.body.error.correlationId).toBeTruthy();
  });

  it("rejects protected routes without a token", async () => {
    const response = await request(app).get("/admin/providers").expect(401);
    expect(response.body.error.code).toBe("unauthenticated");
  });

  it('limits performance reporting to administrators and viewing to SaaS admin', async () => {
    const data = { flow: 'login', totalMs: 1500, authMs: 1000, apiMs: 300 };
    await request(app).post('/admin/performance').send(data).expect(401);
    await request(app).post('/admin/performance').set('Authorization', 'Bearer test-sub').send(data).expect(403);
    await request(app).post('/admin/performance').set('Authorization', 'Bearer test-provider').send(data).expect(204);
    await request(app).get('/admin/metrics').set('Authorization', 'Bearer test-provider').expect(403);
    const response = await request(app).get('/admin/metrics').set('Authorization', 'Bearer test-root').expect(200);
    expect(response.body.panel.some((sample: { role: string }) => sample.role === 'providerAdmin')).toBe(true);
    await request(app).post('/admin/performance').set('Authorization', 'Bearer test-root').send({ ...data, email: 'private@example.test' }).expect(400);
  });
});
