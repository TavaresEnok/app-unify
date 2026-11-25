import { randomUUID } from "node:crypto";
import { Router } from "express";
import { verifySuperAdmin } from "../middlewares/auth";
import { ApiError, asyncRoute } from "../middlewares/errorHandler";
import { recordAdminAudit } from "../services/auditService";
import { decodeCursor, encodeCursor, pageSize } from "../services/cursorPage";
import { ensureCoreSchema, requirePgPool } from "../services/postgres";
import { hashPassword } from "../services/self-auth";

export const usersRouter = Router();
usersRouter.use(verifySuperAdmin);
usersRouter.use((_req, res, next) => {
  res.setHeader("Cache-Control", "private, no-store");
  next();
});

interface AdminRow {
  uid: string;
  email: string;
  role: "superAdmin" | "providerAdmin";
  provider_id: string | null;
  disabled: boolean;
}

function serializeAdmin(row: AdminRow) {
  return {
    id: row.uid,
    uid: row.uid,
    email: row.email,
    superAdmin: row.role === "superAdmin",
    role: row.role,
    providerId: row.provider_id || null,
    disabled: row.disabled === true,
  };
}

usersRouter.get("/page", asyncRoute(async (req, res) => {
  const size = pageSize(req.query.limit);
  const scope = "admin-users";
  const cursor = decodeCursor(req.query.cursor, scope);

  const pool = requirePgPool();
  await ensureCoreSchema(pool);
  const params: unknown[] = [];
  let where = `WHERE role IN ('superAdmin', 'providerAdmin')`;
  if (cursor) {
    params.push(cursor.id);
    where += ` AND uid > $1`;
  }
  params.push(size + 1);
  const rowsRes = await pool.query<AdminRow>(
    `SELECT uid, email, role, provider_id, disabled FROM admin_users ${where} ORDER BY uid ASC LIMIT $${params.length}`,
    params,
  );
  const rows = rowsRes.rows.slice(0, size);
  const last = rows[rows.length - 1];
  res.json({
    data: rows.map(serializeAdmin),
    nextCursor: rowsRes.rows.length > size && last ? encodeCursor(scope, last.uid) : null,
  });
}));

usersRouter.get("/", asyncRoute(async (_req, res) => {
  const pool = requirePgPool();
  await ensureCoreSchema(pool);
  const result = await pool.query<AdminRow>(
    `SELECT uid, email, role, provider_id, disabled
       FROM admin_users
      WHERE role IN ('superAdmin', 'providerAdmin')
      ORDER BY email ASC
      LIMIT 100`,
  );
  res.json({ data: result.rows.map(serializeAdmin) });
}));

usersRouter.post("/", asyncRoute(async (req, res) => {
  const email = typeof req.body?.email === "string" ? req.body.email.trim().toLowerCase() : "";
  const password = typeof req.body?.password === "string" ? req.body.password : "";
  const roleInput = typeof req.body?.role === "string" ? req.body.role.trim() : "";
  const isSuper = req.body?.superAdmin === true || roleInput === "superAdmin";
  const role: "superAdmin" | "providerAdmin" = isSuper ? "superAdmin" : "providerAdmin";
  const providerId = role === "providerAdmin" && typeof req.body?.providerId === "string" ? req.body.providerId.trim() : null;

  if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    throw new ApiError(400, "E-mail inválido.", "invalid-argument");
  }
  if (!password || password.length < 6) {
    throw new ApiError(400, "A senha deve ter pelo menos 6 caracteres.", "invalid-argument");
  }
  if (role === "providerAdmin" && (!providerId || !/^[a-z0-9_-]{1,64}$/i.test(providerId))) {
    throw new ApiError(400, "Provedor obrigatório para administrador de provedor.", "invalid-argument");
  }

  const pool = requirePgPool();
  await ensureCoreSchema(pool);
  const uid = randomUUID().replace(/-/g, "").slice(0, 28);
  const passwordHash = hashPassword(password);

  try {
    const inserted = await pool.query<AdminRow>(
      `INSERT INTO admin_users (uid, email, password_hash, role, provider_id, disabled, token_version, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, FALSE, 1, NOW(), NOW())
       RETURNING uid, email, role, provider_id, disabled`,
      [uid, email, passwordHash, role, providerId],
    );
    await recordAdminAudit({ type: "CREATE_ADMIN_USER", requesterUid: req.user!.uid, providerId: providerId || undefined, correlationId: req.correlationId, payload: { uid, email, role } });
    res.status(201).json({ success: true, data: serializeAdmin(inserted.rows[0]) });
  } catch (error) {
    if ((error as { code?: string }).code === "23505") {
      throw new ApiError(409, "Já existe um usuário com este e-mail.", "already-exists");
    }
    throw error;
  }
}));

usersRouter.post("/super-admin", asyncRoute(async (req, res) => {
  const email = typeof req.body?.email === "string" ? req.body.email.trim().toLowerCase() : "";
  if (!email) throw new ApiError(400, "E-mail obrigatório.", "invalid-argument");

  const pool = requirePgPool();
  await ensureCoreSchema(pool);
  const updated = await pool.query<AdminRow>(
    `UPDATE admin_users
        SET role = 'superAdmin',
            provider_id = NULL,
            token_version = token_version + 1,
            updated_at = NOW()
      WHERE LOWER(email) = $1
      RETURNING uid, email, role, provider_id, disabled`,
    [email],
  );
  if (!updated.rows[0]) throw new ApiError(404, "Usuário não encontrado.", "not-found");
  await recordAdminAudit({ type: "SET_SUPER_ADMIN_BY_EMAIL", requesterUid: req.user!.uid, correlationId: req.correlationId, payload: { uid: updated.rows[0].uid, email } });
  res.json({ success: true, message: "Usuário promovido a Super Admin.", data: serializeAdmin(updated.rows[0]) });
}));

usersRouter.patch("/:uid/password", asyncRoute(async (req, res) => {
  const uid = String(req.params.uid || "").trim();
  const password = typeof req.body?.password === "string" ? req.body.password : "";
  if (!uid) throw new ApiError(400, "UID obrigatório.", "invalid-argument");
  if (!password || password.length < 6) throw new ApiError(400, "A senha deve ter pelo menos 6 caracteres.", "invalid-argument");

  const pool = requirePgPool();
  await ensureCoreSchema(pool);
  const passwordHash = hashPassword(password);
  const updated = await pool.query(
    `UPDATE admin_users SET password_hash = $2, token_version = token_version + 1, updated_at = NOW() WHERE uid = $1`,
    [uid, passwordHash],
  );
  if (!updated.rowCount) throw new ApiError(404, "Usuário não encontrado.", "not-found");
  await recordAdminAudit({ type: "UPDATE_ADMIN_PASSWORD", requesterUid: req.user!.uid, correlationId: req.correlationId, payload: { uid } });
  res.json({ success: true });
}));

usersRouter.delete("/:uid", asyncRoute(async (req, res) => {
  const uid = String(req.params.uid || "").trim();
  if (!uid) throw new ApiError(400, "UID obrigatório.", "invalid-argument");
  if (uid === req.user?.uid) throw new ApiError(400, "Não é possível excluir a própria conta.", "invalid-argument");
  const pool = requirePgPool();
  await ensureCoreSchema(pool);
  const removed = await pool.query(`DELETE FROM admin_users WHERE uid = $1`, [uid]);
  if (!removed.rowCount) throw new ApiError(404, "Usuário não encontrado.", "not-found");
  await recordAdminAudit({ type: "DELETE_ADMIN_USER", requesterUid: req.user!.uid, correlationId: req.correlationId, payload: { uid } });
  res.json({ success: true });
}));
