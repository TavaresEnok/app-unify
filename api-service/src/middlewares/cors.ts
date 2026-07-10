import cors from "cors";
import { env } from "../config/env";

export const corsMiddleware = cors({
  origin: (origin, callback) => {
    if (!origin || env.allowedOrigins.includes(origin)) return callback(null, true);
    callback(new Error("Origem não permitida pela política CORS."));
  },
  credentials: true,
});
