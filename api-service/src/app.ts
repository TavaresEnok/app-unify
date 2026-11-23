import express, { type Request, type Response } from "express";
import { measureRequests, metrics } from "./middlewares/metrics";
import { authenticateIfPresent, verifySuperAdmin, verifyAdmin, verifyToken } from "./middlewares/auth";
import { recordPanelTiming, panelTimings } from "./services/panelTiming";
import { redis } from "./services/redis";
import { getPgPool } from "./services/postgres";
import { env } from "./config/env";
import { corsMiddleware } from "./middlewares/cors";
import { ApiError, correlationId, errorHandler, notFoundHandler } from "./middlewares/errorHandler";
import { globalLimiter } from "./middlewares/rateLimits";
import { adminAuthRouter } from "./routes/adminAuth.routes";
import { providersRouter } from "./routes/providers.routes";
import { ticketsRouter } from "./routes/tickets.routes";
import { privateAttachmentsRouter } from "./routes/privateAttachments.routes";
import { usersRouter } from "./routes/users.routes";
import { dashboardRouter } from "./routes/dashboard.routes";
import { notificationsRouter } from "./routes/notifications.routes";
import { clientsRouter } from "./routes/clients.routes";
import { subscriberRouter } from "./routes/subscriber.routes";
import { adminDiagnosticsRouter, diagnosticsRouter } from "./routes/diagnostics.routes";
import { tr069AdminRouter, tr069SubscriberRouter } from "./routes/tr069.routes";
import { proxyRouter } from "./routes/proxy.routes";
import { buildAuthorizationRouter } from "./routes/buildAuthorization.routes";
import { publicConfigRouter } from "./routes/publicConfig.routes";

export function createApp() {
  const app = express();
  app.disable("x-powered-by");
  app.set("trust proxy", 1);
  app.use(correlationId);
  app.use(measureRequests);
  app.use(corsMiddleware);
  app.use(express.json({ limit: "1mb" }));
  app.use("/internal/builds", buildAuthorizationRouter);
  app.use(authenticateIfPresent);
  app.use(globalLimiter);

  app.get("/admin/metrics", verifySuperAdmin, (_req: Request, res: Response) => res.json({ ...metrics(), panel: panelTimings() }));
  app.post("/admin/performance", verifyToken, verifyAdmin, (req, res, next) => {
    if (!recordPanelTiming(req.body, req.user?.superAdmin === true ? 'superAdmin' : 'providerAdmin')) {
      return next(new ApiError(400, 'Medição inválida.', 'invalid-argument'));
    }
    res.status(204).end();
  });

  app.use("/admin/auth", adminAuthRouter);
  app.use("/admin/providers", providersRouter);
  app.use("/admin/tickets", ticketsRouter);
  app.use("/private", privateAttachmentsRouter);
  app.use("/admin/users", usersRouter);
  app.use("/admin/dashboard", dashboardRouter);
  app.use("/admin/notifications", notificationsRouter);
  app.use("/admin/clients", clientsRouter);
  app.use("/admin/diagnostics", adminDiagnosticsRouter);
  app.use("/admin/tr069", tr069AdminRouter);
  app.use("/diagnostic", diagnosticsRouter);
  app.use("/tr069", tr069SubscriberRouter);
  app.use("/public", publicConfigRouter);
  app.use(subscriberRouter);
  app.use(proxyRouter);

  app.get("/ready", async (_req: Request, res: Response) => {
    try {
      if (!redis && env.nodeEnv === "production") throw new Error("Redis ausente");
      await redis?.ping();
      const pg = getPgPool();
      if (pg) await pg.query("SELECT 1");
      res.json({
        status: "ready",
        service: "api-service",
        checks: {
          redis: redis ? "ok" : "disabled",
          postgres: pg ? "ok" : "disabled",
        },
      });
    } catch { res.status(503).json({ status: "not-ready", service: "api-service" }); }
  });

  app.get("/health", (_req, res) => {
    res.json({ status: "ok", service: "api-service", environment: env.nodeEnv, ts: new Date().toISOString() });
  });

  app.use(notFoundHandler);
  app.use(errorHandler);
  return app;
}
