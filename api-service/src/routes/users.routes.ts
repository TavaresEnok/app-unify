import { Router } from "express";
import { verifySuperAdmin } from "../middlewares/auth";
import { asyncRoute } from "../middlewares/errorHandler";
import { firestore } from "../services/firebaseAdmin";
import { decodeCursor, encodeCursor, pageSize } from "../services/cursorPage";

export const usersRouter = Router();
usersRouter.use(verifySuperAdmin);

usersRouter.get('/page', asyncRoute(async (req, res) => {
  const size = pageSize(req.query.limit);
  const scope = 'admin-users';
  const cursor = decodeCursor(req.query.cursor, scope);
  let query: FirebaseFirestore.Query = firestore.collection('users').where('role', 'in', ['superAdmin', 'providerAdmin']).orderBy('__name__');
  if (cursor) query = query.startAfter(cursor.id);
  const snapshot = await query.limit(size + 1).get();
  const docs = snapshot.docs.slice(0, size);
  res.setHeader('Cache-Control', 'private, no-store');
  res.json({ data: docs.map(user => ({ uid: user.id, email: user.data().email, superAdmin: user.data().superAdmin === true, providerId: user.data().providerId || null })),
    nextCursor: snapshot.docs.length > size ? encodeCursor(scope, docs[docs.length - 1]) : null });
}));

usersRouter.get("/", asyncRoute(async (_req, res) => {
  const result = await firestore.collection("users").where("role", "in", ["superAdmin", "providerAdmin"]).limit(100).get();
  res.json({ data: result.docs.map((user) => ({
    id: user.id, uid: user.id, email: user.data().email,
    superAdmin: user.data().superAdmin === true, providerId: user.data().providerId || null,
  })) });
}));
