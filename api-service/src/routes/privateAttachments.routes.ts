import express, { Router, type RequestHandler } from "express";
import { createHash } from "node:crypto";
import { verifyToken } from "../middlewares/auth";
import { ApiError, asyncRoute } from "../middlewares/errorHandler";
import { admin, firestore, serverTimestamp } from "../services/firebaseAdmin";

const MAX = 5 * 1024 * 1024;
const id = (value: unknown): string => {
  if (typeof value !== "string" || !/^[A-Za-z0-9_-]{1,128}$/.test(value)) throw new ApiError(400, "Identificador inválido.");
  return value;
};
const digest = (bytes: Buffer) => createHash("sha256").update(bytes).digest("hex");
const fail = () => new ApiError(409, "Anexo inconsistente ou indisponível.", "attachment-conflict");
const allowedMetadata = (data: FirebaseFirestore.DocumentData) => Object.keys(data).every(key =>
  ["version", "providerId", "ownerUid", "resourceId", "attachmentId", "path", "checksum", "size", "mime", "state", "generation", "createdAt"].includes(key));
const validUploadState = (data: FirebaseFirestore.DocumentData) =>
  (data.state === "pending" && !Object.prototype.hasOwnProperty.call(data, "generation")) ||
  (data.state === "committed" && typeof data.generation === "string" && /^[1-9][0-9]*$/.test(data.generation));
const privateObject = (object: { metadata?: Record<string, unknown>; contentEncoding?: string }) =>
  !object.contentEncoding && Object.keys(object.metadata || {}).every(key => key === "checksum");

export function validatePrivateBytes(bytes: Buffer, mime: string, report: boolean) {
  if (!Buffer.isBuffer(bytes) || !bytes.length || bytes.length > MAX) throw new ApiError(400, "Arquivo vazio ou maior que 5 MiB.");
  const valid = report
    ? mime === "application/pdf" && bytes.subarray(0, 5).toString() === "%PDF-" && bytes.subarray(-1024).includes(Buffer.from("%%EOF"))
    : (mime === "image/png" && bytes.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10])) && bytes.length >= 45 &&
      bytes.readUInt32BE(8) === 13 && bytes.toString("ascii", 12, 16) === "IHDR" &&
      bytes.readUInt32BE(16) > 0 && bytes.readUInt32BE(16) <= 10000 && bytes.readUInt32BE(20) > 0 && bytes.readUInt32BE(20) <= 10000 &&
      bytes.subarray(-8, -4).toString() === "IEND") ||
      (mime === "image/jpeg" && bytes.length >= 4 && bytes[0] === 255 && bytes[1] === 216 && bytes[2] === 255 && bytes[bytes.length - 2] === 255 && bytes[bytes.length - 1] === 217);
  if (!valid) throw new ApiError(415, "Tipo ou conteúdo de arquivo inválido.");
}

// Shared process cap includes body parsing, Storage I/O and response completion.
let active = 0;
const capacity: RequestHandler = (_req, res, next) => {
  if (active >= 8) return next(new ApiError(503, "Arquivos ocupados. Tente novamente."));
  active++;
  let released = false;
  const release = () => { if (!released) { released = true; active--; } };
  res.locals.privateAttachmentRelease = release;
  const releaseIfIdle = () => { if (!res.locals.privateAttachmentRunning) release(); };
  res.once("close", releaseIfIdle); res.once("finish", releaseIfIdle);
  next();
};

function privateRoute(handler: Parameters<typeof asyncRoute>[0]): RequestHandler {
  return asyncRoute(async (req, res, next) => {
    res.locals.privateAttachmentRunning = true;
    try { return await handler(req, res, next); }
    finally {
      res.locals.privateAttachmentRunning = false;
      if (res.writableFinished || res.destroyed) res.locals.privateAttachmentRelease();
    }
  });
}

export const privateAttachmentsRouter = Router();
privateAttachmentsRouter.use(verifyToken, capacity);

function location(req: Express.Request & { params: Record<string, string> }) {
  const report = !!req.params.provider;
  const resourceId = id(req.params.resource);
  const attachmentId = id(req.params.attachment);
  const resource = report
    ? firestore.collection("provedores").doc(id(req.params.provider)).collection("diagnostic_results").doc(resourceId)
    : firestore.collection("tickets").doc(resourceId);
  return { report, resourceId, attachmentId, resource };
}

function resourceData(snapshot: FirebaseFirestore.DocumentSnapshot, report: boolean) {
  if (!snapshot.exists) return undefined;
  if (report) {
    // Old SDK documents could forge ownership. A body/schema flag alone cannot
    // prove provenance: require canonical Firestore createTime after verified Rules.
    const cutoff = Date.parse(process.env.PRIVATE_DIAGNOSTIC_RULES_ACTIVE_AFTER || "");
    if (!Number.isFinite(cutoff) || !snapshot.createTime || snapshot.createTime.toMillis() <= cutoff || snapshot.data()?.schemaVersion !== 2) {
      throw new ApiError(409, "Relatório legado ou gate de Rules pendente.", "legacy-remediation-required");
    }
  }
  return snapshot.data();
}

function authorize(req: Express.Request, data: FirebaseFirestore.DocumentData | undefined, report: boolean, provider?: string) {
  if (!data) throw new ApiError(404, "Recurso não encontrado.");
  const tenant = id(data.providerId);
  const owner = data.createdByUid;
  if (typeof owner !== "string" || !owner || owner.length > 256) throw fail();
  if (report && tenant !== provider) throw fail();
  const user = req.user!;
  if (!(user.superAdmin === true || (user.providerId === tenant &&
    (user.role === "providerAdmin" || (user.role === "subscriber" && user.uid === owner))))) {
    throw new ApiError(403, "Sem permissão para este recurso.", "permission-denied");
  }
  return { tenant, owner };
}

const paths = ["/tickets/:resource/attachments/:attachment", "/providers/:provider/results/:resource/reports/:attachment"];

const rawBody = express.raw({ type: () => true, limit: MAX, inflate: false });
const boundedBody: RequestHandler = (req, res, next) => rawBody(req, res, error =>
  next(error ? new ApiError((error as { status?: number }).status === 413 ? 413 : 400, "Corpo inválido ou maior que 5 MiB.") : undefined));
privateAttachmentsRouter.put(paths, boundedBody, privateRoute(async (req, res) => {
  if (Object.keys(req.query).length || req.headers["content-encoding"]) throw new ApiError(400, "Metadados não permitidos.");
  const loc = location(req);
  const mime = req.headers["content-type"] || "";
  validatePrivateBytes(req.body, mime, loc.report);
  const checksum = digest(req.body);
  const canonical = authorize(req, resourceData(await loc.resource.get(), loc.report), loc.report, req.params.provider);
  const path = `private_v2/${canonical.tenant}/${loc.report ? "results" : "tickets"}/${loc.resourceId}/${loc.attachmentId}`;
  const ref = loc.resource.collection("private_attachments").doc(loc.attachmentId);
  const expected = { version: 2, providerId: canonical.tenant, ownerUid: canonical.owner, resourceId: loc.resourceId,
    attachmentId: loc.attachmentId, path, checksum, size: req.body.length, mime };
  const matches = (data: FirebaseFirestore.DocumentData) => allowedMetadata(data) && Object.entries(expected).every(([key, value]) => data[key] === value);
  await firestore.runTransaction(async tx => {
    const [resource, previous] = await Promise.all([tx.get(loc.resource), tx.get(ref)]);
    const current = authorize(req, resourceData(resource, loc.report), loc.report, req.params.provider);
    if (current.tenant !== canonical.tenant || current.owner !== canonical.owner) throw fail();
    if (previous.exists) { if (!matches(previous.data()!) || !validUploadState(previous.data()!)) throw fail(); }
    else tx.create(ref, { ...expected, state: "pending", createdAt: serverTimestamp() });
  });
  // Immutable create: a retry may recover only the exact reserved bytes. No overwrite.
  const file = admin.storage().bucket().file(path);
  try {
    await file.save(req.body, { resumable: false, validation: "crc32c", preconditionOpts: { ifGenerationMatch: 0 },
      metadata: { contentType: mime, cacheControl: "private, no-store", metadata: { checksum } } });
  } catch (error) { if (Number((error as { code?: number }).code) !== 412) throw new ApiError(503, "Upload pendente. Tente novamente com o mesmo arquivo."); }
  const [object] = await file.getMetadata();
  if (Number(object.size) !== expected.size || object.contentType !== mime || object.metadata?.checksum !== checksum ||
      !privateObject(object) || typeof object.generation !== "string" || !/^[1-9][0-9]*$/.test(object.generation)) throw fail();
  const pinned = admin.storage().bucket().file(path, { generation: object.generation });
  const [bytes] = await pinned.download({ validation: "crc32c" });
  if (bytes.length !== expected.size || digest(bytes) !== checksum) throw fail();
  // Revalidate current Auth after I/O; no long-lived authority snapshot.
  await new Promise<void>((resolve, reject) => verifyToken(req, res, error => error ? reject(error) : resolve()));
  await firestore.runTransaction(async tx => {
    const [resource, metadata] = await Promise.all([tx.get(loc.resource), tx.get(ref)]);
    const current = authorize(req, resourceData(resource, loc.report), loc.report, req.params.provider);
    if (current.tenant !== canonical.tenant || current.owner !== canonical.owner || !metadata.exists ||
        !matches(metadata.data()!) || !validUploadState(metadata.data()!)) throw fail();
    if (metadata.data()!.state === "committed") {
      if (metadata.data()!.generation !== String(object.generation)) throw fail();
      return;
    }
    tx.set(ref, { ...expected, generation: String(object.generation), state: "committed", createdAt: serverTimestamp() });
    if (loc.report) tx.update(loc.resource, { reportAttachmentId: loc.attachmentId });
    else tx.set(loc.resource.collection("messages").doc(`attachment_${loc.attachmentId}`), {
      attachmentId: loc.attachmentId, senderUid: req.user!.uid, senderEmail: "", createdAt: serverTimestamp(), message: "Anexo privado",
    });
  });
  res.status(200).json({ attachmentId: loc.attachmentId, version: 2 });
}));

privateAttachmentsRouter.get(paths, privateRoute(async (req, res) => {
  if (Object.keys(req.query).length) throw new ApiError(400, "Parâmetros não permitidos.");
  const loc = location(req);
  const canonical = authorize(req, resourceData(await loc.resource.get(), loc.report), loc.report, req.params.provider);
  const ref = loc.resource.collection("private_attachments").doc(loc.attachmentId);
  const metadata = (await ref.get()).data();
  const path = `private_v2/${canonical.tenant}/${loc.report ? "results" : "tickets"}/${loc.resourceId}/${loc.attachmentId}`;
  if (!metadata || !allowedMetadata(metadata) || metadata.state !== "committed" || metadata.version !== 2 || metadata.path !== path ||
      metadata.ownerUid !== canonical.owner || metadata.providerId !== canonical.tenant || metadata.resourceId !== loc.resourceId ||
      metadata.attachmentId !== loc.attachmentId || !/^[0-9]+$/.test(metadata.generation) ||
      !Number.isInteger(metadata.size) || metadata.size <= 0 || metadata.size > MAX) throw fail();
  const file = admin.storage().bucket().file(path, { generation: metadata.generation });
  const [object] = await file.getMetadata();
  if (String(object.generation) !== metadata.generation || Number(object.size) !== metadata.size ||
      object.contentType !== metadata.mime || object.metadata?.checksum !== metadata.checksum || !privateObject(object)) throw fail();
  const [bytes] = await file.download({ validation: "crc32c" });
  if (bytes.length !== metadata.size || digest(bytes) !== metadata.checksum) throw fail();
  validatePrivateBytes(bytes, metadata.mime, loc.report);
  await new Promise<void>((resolve, reject) => verifyToken(req, res, error => error ? reject(error) : resolve()));
  const current = authorize(req, resourceData(await loc.resource.get(), loc.report), loc.report, req.params.provider);
  if (current.tenant !== canonical.tenant || current.owner !== canonical.owner || JSON.stringify((await ref.get()).data()) !== JSON.stringify(metadata)) throw fail();
  res.set({ "Cache-Control": "private, no-store", "X-Content-Type-Options": "nosniff", "Content-Security-Policy": "sandbox; default-src 'none'",
    "Content-Type": metadata.mime, "Content-Disposition": `attachment; filename="attachment.${loc.report ? "pdf" : metadata.mime === "image/png" ? "png" : "jpg"}"` });
  res.send(bytes);
}));
