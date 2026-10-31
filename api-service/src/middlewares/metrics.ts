import type { RequestHandler } from "express";
const routes = new Map<string, { count: number; failures: number; durations: number[] }>();
export const measureRequests: RequestHandler = (req, res, next) => {
  const start = performance.now();
  res.on("finish", () => {
    const key = `${req.method} ${req.baseUrl}${req.route?.path || "unmatched"}`;
    if (!routes.has(key) && routes.size >= 100) return;
    const metric = routes.get(key) || { count: 0, failures: 0, durations: [] };
    metric.count++;
    if (res.statusCode >= 500) metric.failures++;
    metric.durations.push(performance.now() - start);
    if (metric.durations.length > 1000) metric.durations.shift();
    routes.set(key, metric);
  });
  next();
};
export function metrics() {
  return { uptimeSeconds: process.uptime(), memory: process.memoryUsage(), routes: [...routes].map(([route, value]) => {
    const sorted = [...value.durations].sort((a, b) => a - b);
    return { route, count: value.count, failures: value.failures, p95Ms: sorted[Math.max(0, Math.ceil(sorted.length * 0.95) - 1)] || 0 };
  }) };
}
