import cors from "cors";
import { env } from "../config/env";
import { ApiError } from "./errorHandler";

export const corsMiddleware = cors({
  origin: (origin, callback) => {
    if (!origin || env.allowedOrigins.includes(origin)) return callback(null, true);
    // ApiError (e não Error puro) para o errorHandler responder 403 em vez de
    // mascarar como 500 "Erro interno do servidor".
    callback(new ApiError(403, "Origem não permitida pela política CORS.", "forbidden"));
  },
  credentials: true,
});
