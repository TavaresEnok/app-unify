import { spawn } from "node:child_process";
import { ApiError } from "../middlewares/errorHandler";

/** One probe per hop bounds the work; a deadline preserves measured partial hops. */
export function executeTraceroute(target: string, maxHops: number): Promise<{ raw: string; timedOut: boolean }> {
  return new Promise((resolve, reject) => {
    const chunks: Buffer[] = [];
    let timedOut = false;
    const child = spawn("traceroute", ["-n", "-q", "1", "-m", String(maxHops), "-w", "1", target], { stdio: ["ignore", "pipe", "ignore"] });
    const timeout = setTimeout(() => { timedOut = true; child.kill("SIGKILL"); }, 25_000);
    child.stdout.on("data", (chunk: Buffer) => chunks.push(chunk));
    child.on("error", () => {
      clearTimeout(timeout);
      reject(new ApiError(503, "Rastreamento indisponível no servidor.", "unavailable"));
    });
    child.on("close", (code) => {
      clearTimeout(timeout);
      if (code !== 0 && !timedOut) {
        reject(new ApiError(502, "Não foi possível executar o rastreamento.", "upstream-error"));
        return;
      }
      resolve({ raw: Buffer.concat(chunks).toString("utf8"), timedOut });
    });
  });
}
