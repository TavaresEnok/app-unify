import express from "express";
import { env } from "./config/env";
import { corsMiddleware } from "./middlewares/cors";
import { correlationId, errorHandler, notFoundHandler } from "./middlewares/errorHandler";
import { globalLimiter } from "./middlewares/rateLimits";
import { adminAuthRouter } from "./routes/adminAuth.routes";
import { providersRouter } from "./routes/providers.routes";
import { ticketsRouter } from "./routes/tickets.routes";
import { usersRouter } from "./routes/users.routes";
import { dashboardRouter } from "./routes/dashboard.routes";
import { subscriberRouter } from "./routes/subscriber.routes";
import { diagnosticsRouter } from "./routes/diagnostics.routes";
import { proxyRouter } from "./routes/proxy.routes";

export function createApp() {
  const app = express();
  app.disable("x-powered-by");
  app.set("trust proxy", 1);
  app.use(correlationId);
  app.use(corsMiddleware);
  app.use(express.json({ limit: "1mb" }));
  app.use(globalLimiter);

  app.use("/admin/auth", adminAuthRouter);
  app.use("/admin/providers", providersRouter);
  app.use("/admin/tickets", ticketsRouter);
  app.use("/admin/users", usersRouter);
  app.use("/admin/dashboard", dashboardRouter);
  app.use("/diagnostic", diagnosticsRouter);
  app.use(subscriberRouter);
  app.use(proxyRouter);

  app.get("/health", (_req, res) => {
    res.json({ status: "ok", service: "api-service", environment: env.nodeEnv, ts: new Date().toISOString() });
  });

  app.use(notFoundHandler);
  app.use(errorHandler);
  return app;
}
