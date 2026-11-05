import { createApp } from "./app";
import { env, environmentWarnings } from "./config/env";
import { warmDashboardData } from "./routes/dashboard.routes";

export function startServer() {
  environmentWarnings().forEach((message) => console.warn(`[WARN] ${message}`));
  const app = createApp();
  return app.listen(env.port, () => {
    console.log(`API Service rodando na porta ${env.port}`);
    void warmDashboardData().catch(() => console.warn('[WARN] Pré-carregamento do dashboard indisponível; a consulta será repetida no acesso.'));
  });
}
