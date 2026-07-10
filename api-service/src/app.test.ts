import { describe, expect, it } from "vitest";
import request from "supertest";
import { createApp } from "./app";

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
});
