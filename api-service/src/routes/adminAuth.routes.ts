import { Router } from "express";
import { verifyAdmin, verifyToken } from "../middlewares/auth";
import { ApiError, asyncRoute } from "../middlewares/errorHandler";
import { loginLimiter } from "../middlewares/rateLimits";
import { ensureCoreSchema, requirePgPool } from "../services/postgres";
import { signJwt, verifyPassword } from "../services/self-auth";

export const adminAuthRouter = Router();

interface AdminUserRow {
  uid: string;
  email: string;
  password_hash: string;
  role: "superAdmin" | "providerAdmin";
  provider_id: string | null;
  disabled: boolean;
  token_version: number;
}

const ADMIN_TOKEN_TTL_SECONDS = 12 * 3600;

function formatUserResponse(row: AdminUserRow, authTime: number) {
  return {
    uid: row.uid,
    email: row.email,
    role: row.role,
    superAdmin: row.role === "superAdmin",
    providerId: row.provider_id || null,
    authTime,
  };
}

adminAuthRouter.post("/login", loginLimiter, asyncRoute(async (req, res) => {
  const email = typeof req.body?.email === "string" ? req.body.email.trim().toLowerCase() : "";
  const password = typeof req.body?.password === "string" ? req.body.password : "";
  if (!email || !password) throw new ApiError(400, "Email e senha são obrigatórios.", "invalid-argument");

  const pool = requirePgPool();
  await ensureCoreSchema(pool);
  const found = await pool.query<AdminUserRow>(
    `SELECT uid, email, password_hash, role, provider_id, disabled, token_version
       FROM admin_users
      WHERE LOWER(email) = $1
      LIMIT 1`,
    [email],
  );
  const row = found.rows[0];
  if (!row || !verifyPassword(password, row.password_hash)) {
    throw new ApiError(401, "Credenciais inválidas.", "unauthenticated");
  }
  if (row.disabled) {
    throw new ApiError(403, "Conta desativada.", "permission-denied");
  }
  const authTime = Math.floor(Date.now() / 1000);
  const token = signJwt(
    {
      uid: row.uid,
      email: row.email,
      role: row.role,
      superAdmin: row.role === "superAdmin",
      providerId: row.provider_id || undefined,
      tv: row.token_version,
      auth_time: authTime,
    },
    { ttlSeconds: ADMIN_TOKEN_TTL_SECONDS },
  );

  res.setHeader("Cache-Control", "private, no-store");
  res.json({ token, user: formatUserResponse(row, authTime) });
}));

adminAuthRouter.get("/me", verifyToken, verifyAdmin, (req, res) => {
  res.setHeader("Cache-Control", "private, no-store");
  res.json({
    user: {
      uid: req.user!.uid,
      email: req.user!.email || "",
      role: req.user!.superAdmin ? "superAdmin" : "providerAdmin",
      superAdmin: req.user!.superAdmin === true,
      providerId: req.user!.providerId || null,
      authTime: req.user!.auth_time || Math.floor(Date.now() / 1000),
    },
  });
});

adminAuthRouter.post("/reauthenticate", verifyToken, verifyAdmin, asyncRoute(async (req, res) => {
  const password = typeof req.body?.password === "string" ? req.body.password : "";
  if (!password) throw new ApiError(400, "Senha obrigatória.", "invalid-argument");

  const pool = requirePgPool();
  await ensureCoreSchema(pool);
  const found = await pool.query<AdminUserRow>(
    `SELECT uid, email, password_hash, role, provider_id, disabled, token_version
       FROM admin_users
      WHERE uid = $1
      LIMIT 1`,
    [req.user!.uid],
  );
  const row = found.rows[0];
  if (!row || row.disabled || !verifyPassword(password, row.password_hash)) {
    throw new ApiError(403, "Senha atual incorreta.", "permission-denied");
  }

  const authTime = Math.floor(Date.now() / 1000);
  const token = signJwt(
    {
      uid: row.uid,
      email: row.email,
      role: row.role,
      superAdmin: row.role === "superAdmin",
      providerId: row.provider_id || undefined,
      tv: row.token_version,
      auth_time: authTime,
    },
    { ttlSeconds: ADMIN_TOKEN_TTL_SECONDS },
  );

  res.setHeader("Cache-Control", "private, no-store");
  res.json({ token, user: formatUserResponse(row, authTime) });
}));

adminAuthRouter.post("/logout", verifyToken, asyncRoute(async (req, res) => {
  const pool = requirePgPool();
  await ensureCoreSchema(pool);
  if (req.user?.role === "superAdmin" || req.user?.role === "providerAdmin") {
    await pool.query(
      `UPDATE admin_users SET token_version = token_version + 1, updated_at = NOW() WHERE uid = $1`,
      [req.user.uid],
    );
  }
  res.json({ success: true });
}));
