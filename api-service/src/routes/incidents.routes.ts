import { randomUUID } from "node:crypto";
import { Router, type Request } from "express";
import { canAccessProvider, verifyAdmin, verifyToken } from "../middlewares/auth";
import { ApiError, asyncRoute } from "../middlewares/errorHandler";
import { recordAdminAudit } from "../services/auditService";
import { ensureCoreSchema, requirePgPool } from "../services/postgres";
import { invalidateSubscriberIncidentCache } from "./subscriber.routes";

export const incidentsRouter = Router();
incidentsRouter.use(verifyToken, verifyAdmin);
incidentsRouter.use((_req, res, next) => {
  res.setHeader("Cache-Control", "private, no-store");
  next();
});

const ALLOWED_SEVERITIES = new Set(["info", "warning", "critical"]);

function resolveProviderId(req: Request): string {
  const requested = typeof req.query?.providerId === "string"
    ? req.query.providerId.trim()
    : typeof req.body?.providerId === "string"
      ? req.body.providerId.trim()
      : "";
  const providerId = req.user?.superAdmin === true
    ? requested || String(req.user?.providerId || "").trim()
    : String(req.user?.providerId || "").trim();

  if (!providerId || !/^[a-zA-Z0-9_-]{1,64}$/.test(providerId)) {
    throw new ApiError(400, "Provedor obrigatório.", "invalid-argument");
  }
  if (!canAccessProvider(req, providerId)) {
    throw new ApiError(403, "Sem permissão para este provedor.", "permission-denied");
  }
  return providerId;
}

interface IncidentRow {
  id: string;
  provider_id: string;
  title: string;
  message: string;
  area: string | null;
  severity: string;
  estimated_resolution: string | null;
  active: boolean;
  created_at: Date;
  resolved_at: Date | null;
}

function serializeIncident(row: IncidentRow) {
  return {
    id: row.id,
    providerId: row.provider_id,
    title: row.title,
    message: row.message,
    area: row.area,
    severity: row.severity,
    estimatedResolution: row.estimated_resolution,
    active: row.active,
    createdAt: row.created_at instanceof Date ? row.created_at.toISOString() : String(row.created_at),
    resolvedAt: row.resolved_at instanceof Date ? row.resolved_at.toISOString() : row.resolved_at,
  };
}

incidentsRouter.get("/", asyncRoute(async (req, res) => {
  const providerId = resolveProviderId(req);
  const pool = requirePgPool();
  await ensureCoreSchema(pool);
  const result = await pool.query<IncidentRow>(
    `SELECT id, provider_id, title, message, area, severity, estimated_resolution, active, created_at, resolved_at
       FROM incidents
      WHERE provider_id = $1
      ORDER BY created_at DESC
      LIMIT 100`,
    [providerId],
  );
  res.json({ data: result.rows.map(serializeIncident) });
}));

incidentsRouter.post("/", asyncRoute(async (req, res) => {
  const providerId = resolveProviderId(req);
  const title = typeof req.body?.title === "string" ? req.body.title.trim() : "";
  const message = typeof req.body?.message === "string" ? req.body.message.trim() : "";
  if (!title || !message) {
    throw new ApiError(400, "Título e mensagem do aviso são obrigatórios.", "invalid-argument");
  }
  const severity = typeof req.body?.severity === "string" && ALLOWED_SEVERITIES.has(req.body.severity)
    ? req.body.severity
    : "warning";
  const area = typeof req.body?.area === "string" && req.body.area.trim() ? req.body.area.trim().slice(0, 120) : null;
  const estimated = typeof req.body?.estimatedResolution === "string" && req.body.estimatedResolution.trim()
    ? req.body.estimatedResolution.trim().slice(0, 120)
    : null;

  const pool = requirePgPool();
  await ensureCoreSchema(pool);
  const id = randomUUID().replace(/-/g, "").slice(0, 20);
  const inserted = await pool.query<IncidentRow>(
    `INSERT INTO incidents (id, provider_id, title, message, area, severity, estimated_resolution, active, created_at)
     VALUES ($1, $2, $3, $4, $5, $6, $7, TRUE, NOW())
     RETURNING id, provider_id, title, message, area, severity, estimated_resolution, active, created_at, resolved_at`,
    [id, providerId, title.slice(0, 200), message.slice(0, 2000), area, severity, estimated],
  );
  invalidateSubscriberIncidentCache(providerId);
  await recordAdminAudit({ type: "CREATE_INCIDENT", requesterUid: req.user!.uid, providerId, correlationId: req.correlationId, payload: { id, title } });
  res.status(201).json({ success: true, data: serializeIncident(inserted.rows[0]) });
}));

incidentsRouter.patch("/:id", asyncRoute(async (req, res) => {
  const id = String(req.params.id || "").trim();
  if (!/^[a-zA-Z0-9_-]{1,64}$/.test(id)) throw new ApiError(400, "Identificador inválido.", "invalid-argument");
  const pool = requirePgPool();
  await ensureCoreSchema(pool);
  const existing = await pool.query<{ provider_id: string }>(`SELECT provider_id FROM incidents WHERE id = $1 LIMIT 1`, [id]);
  if (!existing.rows[0]) throw new ApiError(404, "Aviso não encontrado.", "not-found");
  const providerId = existing.rows[0].provider_id;
  if (!canAccessProvider(req, providerId)) throw new ApiError(403, "Sem permissão.", "permission-denied");
  const active = Boolean(req.body?.active);
  const updated = await pool.query<IncidentRow>(
    `UPDATE incidents
        SET active = $2,
            resolved_at = CASE WHEN $2 THEN NULL ELSE NOW() END
      WHERE id = $1
      RETURNING id, provider_id, title, message, area, severity, estimated_resolution, active, created_at, resolved_at`,
    [id, active],
  );
  invalidateSubscriberIncidentCache(providerId);
  res.json({ success: true, data: serializeIncident(updated.rows[0]) });
}));

incidentsRouter.delete("/:id", asyncRoute(async (req, res) => {
  const id = String(req.params.id || "").trim();
  if (!/^[a-zA-Z0-9_-]{1,64}$/.test(id)) throw new ApiError(400, "Identificador inválido.", "invalid-argument");
  const pool = requirePgPool();
  await ensureCoreSchema(pool);
  const existing = await pool.query<{ provider_id: string }>(`SELECT provider_id FROM incidents WHERE id = $1 LIMIT 1`, [id]);
  if (!existing.rows[0]) throw new ApiError(404, "Aviso não encontrado.", "not-found");
  const providerId = existing.rows[0].provider_id;
  if (!canAccessProvider(req, providerId)) throw new ApiError(403, "Sem permissão.", "permission-denied");
  await pool.query(`DELETE FROM incidents WHERE id = $1`, [id]);
  invalidateSubscriberIncidentCache(providerId);
  res.json({ success: true });
}));
