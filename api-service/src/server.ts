import { createApp } from "./app";
import { env, environmentWarnings } from "./config/env";
import { warmDashboardData } from "./routes/dashboard.routes";
import { messaging } from "./services/firebaseAdmin";
import { processDueScheduledCampaigns } from "./services/notificationCampaigns";
import { getPgPool } from "./services/postgres";

export function startServer() {
  environmentWarnings().forEach((message) => console.warn(`[WARN] ${message}`));
  const app = createApp();
  const server = app.listen(env.port, () => {
    console.log(`API Service rodando na porta ${env.port}`);
    void warmDashboardData().catch(() => console.warn('[WARN] Pré-carregamento do dashboard indisponível; a consulta será repetida no acesso.'));
  });

  if (env.nodeEnv !== "test") {
    const tick = () => {
      const pool = getPgPool();
      if (!pool) return;
      void processDueScheduledCampaigns(pool, messaging).catch((error) => {
        console.warn(JSON.stringify({ severity: "WARNING", message: "scheduled.campaigns.tick_failed", error: (error as Error).message }));
      });
    };
    const timer = setInterval(tick, 60_000);
    timer.unref();
    setTimeout(tick, 10_000).unref();
  }

  return server;
}
