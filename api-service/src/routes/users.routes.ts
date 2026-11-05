import { Router } from "express";
import { verifySuperAdmin } from "../middlewares/auth";
import { asyncRoute } from "../middlewares/errorHandler";
import { firestore } from "../services/firebaseAdmin";

export const usersRouter = Router();
usersRouter.use(verifySuperAdmin);

usersRouter.get("/", asyncRoute(async (_req, res) => {
  const result = await firestore.collection("users").where("role", "in", ["superAdmin", "providerAdmin"]).limit(100).get();
  res.json({ data: result.docs.map((user) => ({
    id: user.id, uid: user.id, email: user.data().email,
    superAdmin: user.data().superAdmin === true, providerId: user.data().providerId || null,
  })) });
}));
