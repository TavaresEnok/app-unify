import { Router } from "express";
import { verifyAdmin, verifyToken } from "../middlewares/auth";
import { ApiError, asyncRoute } from "../middlewares/errorHandler";
import { loginAccountLimiter, loginLimiter, passwordChangeLimiter, reauthLimiter } from "../middlewares/rateLimits";
import { recordAdminAudit } from "../services/auditService";
import { ensureCoreSchema, requirePgPool } from "../services/postgres";
import { hashPasswordAsync, passwordPolicyError, signJwt, verifyPasswordAsync } from "../services/self-auth";

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

function issueAdminToken(row: AdminUserRow, authTime: number): string {
  return signJwt(
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
}

// Senha nova do próprio admin: mínimo 10 caracteres com letras e números.
export const ADMIN_PASSWORD_POLICY = { minLength: 10, requireMixed: false } as const;
function adminPasswordProblem(password: string): string | null {
  const basic = passwordPolicyError(password, ADMIN_PASSWORD_POLICY);
  if (basic) return basic;
  if (!/[A-Za-z]/.test(password) || !/\d/.test(password)) return "A senha precisa ter letras e números.";
  return null;
}

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

adminAuthRouter.post("/login", loginLimiter, loginAccountLimiter, asyncRoute(async (req, res) => {
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
  // Sempre calcula o hash (conta inexistente usa um hash fixo) e responde com
  // a mesma mensagem para conta desativada: nada revela quais e-mails existem.
  const valid = await verifyPasswordAsync(password, row?.password_hash);
  if (!row || !valid || row.disabled) {
    throw new ApiError(401, "Credenciais inválidas.", "unauthenticated");
  }
  const authTime = Math.floor(Date.now() / 1000);
  const token = issueAdminToken(row, authTime);

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

adminAuthRouter.post("/reauthenticate", verifyToken, verifyAdmin, reauthLimiter, asyncRoute(async (req, res) => {
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
  const valid = await verifyPasswordAsync(password, row?.password_hash);
  if (!row || row.disabled || !valid) {
    throw new ApiError(403, "Senha atual incorreta.", "permission-denied");
  }

  const authTime = Math.floor(Date.now() / 1000);
  const token = issueAdminToken(row, authTime);

  res.setHeader("Cache-Control", "private, no-store");
  res.json({ token, user: formatUserResponse(row, authTime) });
}));

// Troca da própria senha. Confere a senha atual, encerra as outras sessões
// (token_version + 1) e devolve um token novo para esta sessão continuar.
adminAuthRouter.post("/password", verifyToken, verifyAdmin, passwordChangeLimiter, asyncRoute(async (req, res) => {
  const currentPassword = typeof req.body?.currentPassword === "string" ? req.body.currentPassword : "";
  const newPassword = typeof req.body?.newPassword === "string" ? req.body.newPassword : "";
  if (!currentPassword || !newPassword) throw new ApiError(400, "Informe a senha atual e a nova senha.", "invalid-argument");
  const problem = adminPasswordProblem(newPassword);
  if (problem) throw new ApiError(400, problem, "invalid-argument");
  if (newPassword === currentPassword) throw new ApiError(400, "A nova senha precisa ser diferente da atual.", "invalid-argument");

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
  const valid = await verifyPasswordAsync(currentPassword, row?.password_hash);
  if (!row || row.disabled || !valid) throw new ApiError(403, "Senha atual incorreta.", "permission-denied");

  const passwordHash = await hashPasswordAsync(newPassword, ADMIN_PASSWORD_POLICY);
  const updated = await pool.query<{ token_version: number }>(
    `UPDATE admin_users
        SET password_hash = $2, token_version = token_version + 1, updated_at = NOW()
      WHERE uid = $1 AND token_version = $3
      RETURNING token_version`,
    [row.uid, passwordHash, row.token_version],
  );
  const nextVersion = updated.rows[0]?.token_version;
  if (!Number.isInteger(Number(nextVersion))) throw new ApiError(409, "A conta mudou durante a troca. Tente de novo.", "aborted");
  await recordAdminAudit({ type: "CHANGE_OWN_PASSWORD", requesterUid: row.uid, providerId: row.provider_id || undefined, correlationId: req.correlationId }).catch(() => undefined);

  const authTime = Math.floor(Date.now() / 1000);
  const fresh = { ...row, token_version: Number(nextVersion) };
  res.setHeader("Cache-Control", "private, no-store");
  res.json({ ok: true, token: issueAdminToken(fresh, authTime), user: formatUserResponse(fresh, authTime) });
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
