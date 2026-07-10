import { Router } from "express";
import axios from "axios";
import { env } from "../config/env";
import { loginLimiter } from "../middlewares/rateLimits";
import { ApiError, asyncRoute } from "../middlewares/errorHandler";

export const adminAuthRouter = Router();

adminAuthRouter.post("/login", loginLimiter, asyncRoute(async (req, res) => {
  if (!env.firebaseApiKey) throw new ApiError(503, "Serviço de autenticação não configurado.", "service-unavailable");
  const email = typeof req.body?.email === "string" ? req.body.email.trim() : "";
  const password = typeof req.body?.password === "string" ? req.body.password : "";
  if (!email || !password) throw new ApiError(400, "Email e senha são obrigatórios.", "invalid-argument");
  try {
    const response = await axios.post(
      `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${env.firebaseApiKey}`,
      { email, password, returnSecureToken: true },
      { timeout: 15_000 },
    );
    res.json({ token: response.data.idToken, user: { uid: response.data.localId, email: response.data.email } });
  } catch (error) {
    const code = axios.isAxiosError(error) ? error.response?.data?.error?.message : undefined;
    const invalid = ["INVALID_LOGIN_CREDENTIALS", "INVALID_PASSWORD", "EMAIL_NOT_FOUND", "INVALID_EMAIL"].includes(code);
    throw new ApiError(401, invalid ? "Credenciais inválidas." : "Falha na autenticação.", "unauthenticated");
  }
}));
