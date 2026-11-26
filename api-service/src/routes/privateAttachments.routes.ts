import express, { Router, type RequestHandler } from "express";
import { createHash, randomUUID } from "node:crypto";
import fs from "node:fs/promises";
import path from "node:path";
import { verifyToken, verifyFreshToken } from "../middlewares/auth";
import { ApiError, asyncRoute } from "../middlewares/errorHandler";
import { attachmentUploadLimiter } from "../middlewares/rateLimits";
import { ensureCoreSchema, requirePgPool, type SqlQueryable } from "../services/postgres";

const MAX = 5 * 1024 * 1024;
// Cotas do assinante: protegem o disco (Postgres e uploads dividem o volume).
const MAX_ATTACHMENTS_PER_TICKET = 5;
const MAX_SUBSCRIBER_BYTES_PER_DAY = 25 * 1024 * 1024;
const MIN_FREE_BYTES = Number(process.env.UPLOADS_MIN_FREE_BYTES) > 0 ? Number(process.env.UPLOADS_MIN_FREE_BYTES) : 2 * 1024 * 1024 * 1024;

async function assertDiskSpace(dir: string, incoming: number): Promise<void> {
  const statfs = (fs as unknown as { statfs?: (p: string) => Promise<{ bavail: number | bigint; bsize: number | bigint }> }).statfs;
  if (typeof statfs !== "function") return;
  let free: number;
  try {
    const stats = await statfs(dir);
    free = Number(stats.bavail) * Number(stats.bsize);
  } catch {
    return;
  }
  if (Number.isFinite(free) && free - incoming < MIN_FREE_BYTES) {
    throw new ApiError(507, "Não foi possível guardar o arquivo agora. Tente mais tarde.", "storage-full");
  }
}

async function assertSubscriberQuota(pool: SqlQueryable, resourceKind: string, resourceId: string, ownerUid: string, incoming: number): Promise<void> {
  const [perTicket, perDay] = await Promise.all([
    pool.query<{ count: string | number }>(
      `SELECT COUNT(*) AS count FROM private_attachments WHERE resource_kind = $1 AND resource_id = $2`,
      [resourceKind, resourceId],
    ),
    pool.query<{ bytes: string | number }>(
      `SELECT COALESCE(SUM(size_bytes), 0) AS bytes FROM private_attachments WHERE owner_uid = $1 AND created_at > NOW() - INTERVAL '1 day'`,
      [ownerUid],
    ),
  ]);
  if (Number(perTicket.rows[0]?.count || 0) >= MAX_ATTACHMENTS_PER_TICKET) {
    throw new ApiError(429, `Limite de ${MAX_ATTACHMENTS_PER_TICKET} anexos por chamado.`, "resource-exhausted");
  }
  if (Number(perDay.rows[0]?.bytes || 0) + incoming > MAX_SUBSCRIBER_BYTES_PER_DAY) {
    throw new ApiError(429, "Limite diário de anexos atingido. Tente amanhã.", "resource-exhausted");
  }
}

const subscriberUploadLimiter: RequestHandler = (req, res, next) =>
  (req.user?.role === "subscriber" ? attachmentUploadLimiter(req, res, next) : next());
const id = (value: unknown): string => {
  if (typeof value !== "string" || !/^[A-Za-z0-9_-]{1,128}$/.test(value)) throw new ApiError(400, "Identificador inválido.");
  return value;
};
const digest = (bytes: Buffer) => createHash("sha256").update(bytes).digest("hex");
const fail = () => new ApiError(409, "Anexo inconsistente ou indisponível.", "attachment-conflict");

function privateRootDir(): string {
  return path.resolve(process.env.UPLOADS_DIR?.trim() || "/srv/uploads", "private");
}

function safeDiskPath(relPath: string): string {
  const root = privateRootDir();
  const full = path.resolve(root, relPath);
  if (!full.startsWith(`${root}${path.sep}`)) throw fail();
  return full;
}

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

interface ResourceMeta {
  report: boolean;
  providerParam?: string;
  resourceKind: "ticket" | "diagnostic_result";
  resourceId: string;
  attachmentId: string;
}

function parseLocation(req: Express.Request & { params: Record<string, string> }): ResourceMeta {
  const report = Boolean(req.params.provider);
  const providerParam = report ? id(req.params.provider) : undefined;
  const resourceId = id(req.params.resource);
  const attachmentId = id(req.params.attachment);
  return {
    report,
    providerParam,
    resourceKind: report ? "diagnostic_result" : "ticket",
    resourceId,
    attachmentId,
  };
}

async function fetchResourceAuthority(pool: SqlQueryable, loc: ResourceMeta, req: Express.Request) {
  await ensureCoreSchema(pool);
  let row: { provider_id: string; owner_uid: string } | undefined;
  if (loc.report) {
    const res = await pool.query<{ provider_id: string; created_by_uid: string }>(
      `SELECT provider_id, created_by_uid FROM diagnostic_results WHERE id = $1 AND provider_id = $2 LIMIT 1`,
      [loc.resourceId, loc.providerParam],
    );
    if (res.rows[0]) {
      row = { provider_id: res.rows[0].provider_id, owner_uid: res.rows[0].created_by_uid };
    }
  } else {
    const res = await pool.query<{ provider_id: string; created_by_uid: string }>(
      `SELECT provider_id, created_by_uid FROM tickets WHERE id = $1 LIMIT 1`,
      [loc.resourceId],
    );
    if (res.rows[0]) {
      row = { provider_id: res.rows[0].provider_id, owner_uid: res.rows[0].created_by_uid };
    }
  }
  if (!row) throw new ApiError(404, "Recurso não encontrado.");
  const tenant = id(row.provider_id);
  const owner = row.owner_uid;
  if (typeof owner !== "string" || !owner || owner.length > 256) throw fail();
  if (loc.report && tenant !== loc.providerParam) throw fail();

  const user = req.user!;
  if (!(user.superAdmin === true || (user.providerId === tenant &&
      (user.role === "providerAdmin" || (user.role === "subscriber" && user.uid === owner))))) {
    throw new ApiError(403, "Sem permissão para este recurso.", "permission-denied");
  }
  return { tenant, owner };
}

interface AttachmentRow {
  id: string;
  resource_kind: string;
  resource_id: string;
  attachment_id: string;
  provider_id: string;
  owner_uid: string;
  rel_path: string;
  checksum: string;
  size_bytes: number;
  mime: string;
  state: string;
}

const paths = ["/tickets/:resource/attachments/:attachment", "/providers/:provider/results/:resource/reports/:attachment"];
const rawBody = express.raw({ type: () => true, limit: MAX, inflate: false });
const boundedBody: RequestHandler = (req, res, next) => rawBody(req, res, (error) =>
  next(error ? new ApiError((error as { status?: number }).status === 413 ? 413 : 400, "Corpo inválido ou maior que 5 MiB.") : undefined));

privateAttachmentsRouter.put(paths, subscriberUploadLimiter, boundedBody, privateRoute(async (req, res) => {
  if (Object.keys(req.query).length || req.headers["content-encoding"]) throw new ApiError(400, "Metadados não permitidos.");
  const loc = parseLocation(req);
  const mime = String(req.headers["content-type"] || "").split(";")[0].trim();
  validatePrivateBytes(req.body, mime, loc.report);
  const checksum = digest(req.body);
  const pool = requirePgPool();
  const canonical = await fetchResourceAuthority(pool, loc, req);
  const relPath = path.join(canonical.tenant, loc.report ? "results" : "tickets", loc.resourceId, loc.attachmentId);
  const diskPath = safeDiskPath(relPath);

  const existingRes = await pool.query<AttachmentRow>(
    `SELECT * FROM private_attachments WHERE resource_kind = $1 AND resource_id = $2 AND attachment_id = $3 LIMIT 1`,
    [loc.resourceKind, loc.resourceId, loc.attachmentId],
  );
  const existing = existingRes.rows[0];
  if (existing) {
    if (existing.provider_id !== canonical.tenant || existing.owner_uid !== canonical.owner ||
        existing.checksum !== checksum || Number(existing.size_bytes) !== req.body.length ||
        existing.mime !== mime || existing.rel_path !== relPath) {
      throw fail();
    }
    if (existing.state === "committed") {
      return res.status(200).json({ attachmentId: loc.attachmentId, version: 2 });
    }
  } else {
    if (req.user?.role === "subscriber") await assertSubscriberQuota(pool, loc.resourceKind, loc.resourceId, canonical.owner, req.body.length);
    await fs.mkdir(privateRootDir(), { recursive: true }).catch(() => undefined);
    await assertDiskSpace(privateRootDir(), req.body.length);
    const rowId = randomUUID().replace(/-/g, "").slice(0, 24);
    await pool.query(
      `INSERT INTO private_attachments (id, resource_kind, resource_id, attachment_id, provider_id, owner_uid, rel_path, checksum, size_bytes, mime, state, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, 'pending', NOW())`,
      [rowId, loc.resourceKind, loc.resourceId, loc.attachmentId, canonical.tenant, canonical.owner, relPath, checksum, req.body.length, mime],
    );
  }

  await fs.mkdir(path.dirname(diskPath), { recursive: true });
  try {
    await fs.writeFile(diskPath, req.body, { flag: "wx", mode: 0o600 });
  } catch (error) {
    if ((error as { code?: string }).code !== "EEXIST") {
      throw new ApiError(503, "Falha ao gravar arquivo privado. Tente novamente.");
    }
  }

  const storedBytes = await fs.readFile(diskPath);
  if (storedBytes.length !== req.body.length || digest(storedBytes) !== checksum) throw fail();

  await new Promise<void>((resolve, reject) => verifyFreshToken(req, res, (error) => (error ? reject(error) : resolve())));
  const current = await fetchResourceAuthority(pool, loc, req);
  if (current.tenant !== canonical.tenant || current.owner !== canonical.owner) throw fail();

  await pool.query(
    `UPDATE private_attachments SET state = 'committed'
      WHERE resource_kind = $1 AND resource_id = $2 AND attachment_id = $3
        AND provider_id = $4 AND owner_uid = $5 AND checksum = $6 AND size_bytes = $7 AND mime = $8`,
    [loc.resourceKind, loc.resourceId, loc.attachmentId, canonical.tenant, canonical.owner, checksum, req.body.length, mime],
  );

  if (loc.report) {
    await pool.query(
      `UPDATE diagnostic_results SET report_attachment_id = $2 WHERE id = $1 AND provider_id = $3`,
      [loc.resourceId, loc.attachmentId, canonical.tenant],
    );
  } else {
    const msgId = `att_${loc.attachmentId}`;
    await pool.query(
      `INSERT INTO ticket_messages (id, ticket_id, sender_uid, sender_email, sender_role, message, attachment_id, read, created_at)
       VALUES ($1, $2, $3, $4, $5, 'Anexo privado', $6, FALSE, NOW())
       ON CONFLICT (id) DO NOTHING`,
      [msgId, loc.resourceId, req.user!.uid, req.user?.email || "", req.user?.role || "subscriber", loc.attachmentId],
    );
  }

  res.status(200).json({ attachmentId: loc.attachmentId, version: 2 });
}));

privateAttachmentsRouter.get(paths, privateRoute(async (req, res) => {
  if (Object.keys(req.query).length) throw new ApiError(400, "Parâmetros não permitidos.");
  const loc = parseLocation(req);
  const pool = requirePgPool();
  const canonical = await fetchResourceAuthority(pool, loc, req);

  const metaRes = await pool.query<AttachmentRow>(
    `SELECT * FROM private_attachments WHERE resource_kind = $1 AND resource_id = $2 AND attachment_id = $3 LIMIT 1`,
    [loc.resourceKind, loc.resourceId, loc.attachmentId],
  );
  const metadata = metaRes.rows[0];
  const expectedRelPath = path.join(canonical.tenant, loc.report ? "results" : "tickets", loc.resourceId, loc.attachmentId);
  if (!metadata || metadata.state !== "committed" || metadata.rel_path !== expectedRelPath ||
      metadata.owner_uid !== canonical.owner || metadata.provider_id !== canonical.tenant ||
      !Number.isInteger(Number(metadata.size_bytes)) || metadata.size_bytes <= 0 || metadata.size_bytes > MAX) {
    throw fail();
  }

  const diskPath = safeDiskPath(metadata.rel_path);
  let bytes: Buffer;
  try {
    bytes = await fs.readFile(diskPath);
  } catch {
    throw fail();
  }
  if (bytes.length !== Number(metadata.size_bytes) || digest(bytes) !== metadata.checksum) throw fail();
  validatePrivateBytes(bytes, metadata.mime, loc.report);

  await new Promise<void>((resolve, reject) => verifyFreshToken(req, res, (error) => (error ? reject(error) : resolve())));
  const current = await fetchResourceAuthority(pool, loc, req);
  if (current.tenant !== canonical.tenant || current.owner !== canonical.owner) throw fail();

  res.set({
    "Cache-Control": "private, no-store",
    "X-Content-Type-Options": "nosniff",
    "Content-Security-Policy": "sandbox; default-src 'none'",
    "Content-Type": metadata.mime,
    "Content-Disposition": `attachment; filename="attachment.${loc.report ? "pdf" : metadata.mime === "image/png" ? "png" : "jpg"}"`,
  });
  res.send(bytes);
}));
