import { Router } from "express";
import { verifySuperAdmin } from "../middlewares/auth";
import { asyncRoute } from "../middlewares/errorHandler";
import { firebaseAuth } from "../services/firebaseAdmin";

export const usersRouter = Router();
usersRouter.use(verifySuperAdmin);

usersRouter.get("/", asyncRoute(async (_req, res) => {
  const result = await firebaseAuth.listUsers(1000);
  res.json({ data: result.users.filter((user) => user.customClaims?.superAdmin || user.customClaims?.providerId).map((user) => ({
    id: user.uid,
    uid: user.uid,
    email: user.email,
    superAdmin: user.customClaims?.superAdmin === true,
    providerId: user.customClaims?.providerId || null,
  })) });
}));
