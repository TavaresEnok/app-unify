import { createApp } from "./app";
import { env, environmentWarnings } from "./config/env";

export function startServer() {
  environmentWarnings().forEach((message) => console.warn(`[WARN] ${message}`));
  const app = createApp();
  return app.listen(env.port, () => {
    console.log(`API Service rodando na porta ${env.port}`);
  });
}
