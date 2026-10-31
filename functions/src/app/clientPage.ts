import { db } from "./firebase";
import { AppError } from "./errors";

export async function clientPage(providerId: string, options: { limit?: unknown; cursor?: unknown; search?: unknown }) {
  const limit = Math.min(50, Math.max(1, Math.trunc(Number(options.limit) || 25)));
  const collection = db.collection("provedores").doc(providerId).collection("clientes");
  const search = typeof options.search === "string" ? options.search.trim().slice(0, 100) : "";
  let base: FirebaseFirestore.Query = collection;
  if (search) base = base.where("nome", ">=", search).where("nome", "<=", `${search}\uf8ff`);
  let query = base.orderBy("nome").orderBy("__name__");
  if (options.cursor) {
    if (typeof options.cursor !== "string" || options.cursor.includes("/") || options.cursor.length > 256) {
      throw new AppError("invalid-argument", "Cursor inválido.");
    }
    const cursor = await collection.doc(options.cursor).get();
    if (!cursor.exists) throw new AppError("invalid-argument", "Cursor expirado. Reinicie a busca.");
    query = query.startAfter(cursor);
  }
  const [snapshot, total] = await Promise.all([
    query.limit(limit + 1).select("id", "nome", "cpfcnpj", "cpfCnpj", "status", "plano", "cidade", "providerId", "contratos").get(),
    base.count().get(),
  ]);
  const documents = snapshot.docs.slice(0, limit);
  return {
    items: documents.map((doc) => {
      const { contratos, ...data } = doc.data();
      return { ...data, id: String(data.id || doc.id), documentId: doc.id, providerId,
        cpfcnpj: String(data.cpfCnpj || data.cpfcnpj || doc.id).replace(/\D/g, ''),
        contratos: Array.isArray(contratos) ? contratos.slice(0, 10).map((contract) => ({
          id: contract?.id ?? contract?.contratoId ?? null,
          status: contract?.status ?? contract?.contratoStatusDisplay ?? null,
        })) : [] };
    }),
    nextCursor: snapshot.size > limit ? documents[documents.length - 1].id : null,
    total: total.data().count,
  };
}
