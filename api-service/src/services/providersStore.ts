import { randomUUID } from "node:crypto";
import { ensureCoreSchema, getPgPool, type SqlQueryable } from "./postgres";
import { publicProviderData } from "./providerConfig";
import { decryptSecret, encryptSecret } from "./self-auth";

export interface StoredProviderRow {
  id: string;
  name: string;
  active: boolean;
  data: Record<string, unknown>;
  created_at: Date | string;
  updated_at: Date | string;
}

function toIso(value: unknown): string | undefined {
  if (!value) return undefined;
  if (value instanceof Date) return value.toISOString();
  if (typeof value === "string") return value;
  return undefined;
}

export function serializeProviderRow(row: StoredProviderRow): Record<string, unknown> {
  const raw = row.data && typeof row.data === "object" && !Array.isArray(row.data) ? { ...row.data } : {};
  delete raw.integrations;
  if (raw.config && typeof raw.config === "object" && !Array.isArray(raw.config)) {
    raw.config = { ...(raw.config as Record<string, unknown>) };
    delete (raw.config as Record<string, unknown>).integrations;
  }
  raw.name = row.name || (typeof raw.name === "string" ? raw.name : "");
  raw.active = row.active !== false;
  raw.createdAt = toIso(row.created_at) ?? raw.createdAt;
  raw.updatedAt = toIso(row.updated_at) ?? raw.updatedAt;
  return { ...publicProviderData(raw), id: row.id };
}

export async function getProviderRow(db: SqlQueryable, providerId: string): Promise<StoredProviderRow | null> {
  await ensureCoreSchema(db);
  const res = await db.query<StoredProviderRow>(
    `SELECT id, name, active, data, created_at, updated_at FROM providers WHERE id = $1 LIMIT 1`,
    [providerId],
  );
  return res.rows[0] || null;
}

export async function listProviderRows(db: SqlQueryable): Promise<StoredProviderRow[]> {
  await ensureCoreSchema(db);
  const res = await db.query<StoredProviderRow>(
    `SELECT id, name, active, data, created_at, updated_at FROM providers ORDER BY name ASC, id ASC`,
  );
  return res.rows;
}

export async function upsertProvider(
  db: SqlQueryable,
  providerId: string | null,
  input: Record<string, unknown>,
  options: { replaceData?: boolean } = {},
): Promise<StoredProviderRow> {
  await ensureCoreSchema(db);
  const id = providerId || randomUUID().replace(/-/g, "").slice(0, 20);
  const existing = providerId ? await getProviderRow(db, id) : null;
  const currentData = existing?.data && typeof existing.data === "object" && !Array.isArray(existing.data)
    ? existing.data
    : {};

  const nextData = options.replaceData
    ? { ...input }
    : mergeDeep(currentData, input);
  delete nextData.integrations;
  if (nextData.config && typeof nextData.config === "object" && !Array.isArray(nextData.config)) {
    delete (nextData.config as Record<string, unknown>).integrations;
  }

  const name = typeof nextData.name === "string" && nextData.name.trim()
    ? nextData.name.trim()
    : existing?.name || id;
  const active = typeof nextData.active === "boolean"
    ? nextData.active
    : existing?.active ?? true;

  nextData.name = name;
  nextData.active = active;

  const res = await db.query<StoredProviderRow>(
    `INSERT INTO providers (id, name, active, data, created_at, updated_at)
     VALUES ($1, $2, $3, $4::jsonb, NOW(), NOW())
     ON CONFLICT (id) DO UPDATE SET
       name = EXCLUDED.name,
       active = EXCLUDED.active,
       data = EXCLUDED.data,
       updated_at = NOW()
     RETURNING id, name, active, data, created_at, updated_at`,
    [id, name, active, JSON.stringify(nextData)],
  );
  return res.rows[0];
}

export async function deleteProviderRow(db: SqlQueryable, providerId: string): Promise<boolean> {
  await ensureCoreSchema(db);
  const res = await db.query(`DELETE FROM providers WHERE id = $1`, [providerId]);
  return (res.rowCount || 0) > 0;
}

export async function getProviderSecret<T = Record<string, any>>(
  db: SqlQueryable,
  providerId: string,
  kind: "erp" | "acs",
): Promise<T | null> {
  await ensureCoreSchema(db);
  const res = await db.query<{ ciphertext: string }>(
    `SELECT ciphertext FROM provider_secrets WHERE provider_id = $1 AND kind = $2 LIMIT 1`,
    [providerId, kind],
  );
  const row = res.rows[0];
  if (!row?.ciphertext) return null;
  const decoded = decryptSecret(row.ciphertext);
  return (typeof decoded === "string" ? JSON.parse(decoded) : decoded) as T;
}

export async function saveProviderSecret(
  db: SqlQueryable,
  providerId: string,
  kind: "erp" | "acs",
  secretValue: unknown,
): Promise<void> {
  await ensureCoreSchema(db);
  const ciphertext = encryptSecret(secretValue);
  await db.query(
    `INSERT INTO provider_secrets (provider_id, kind, ciphertext, updated_at)
     VALUES ($1, $2, $3, NOW())
     ON CONFLICT (provider_id, kind) DO UPDATE SET
       ciphertext = EXCLUDED.ciphertext,
       updated_at = NOW()`,
    [providerId, kind, ciphertext],
  );
}

export async function listProviderBackups(db: SqlQueryable, providerId: string) {
  await ensureCoreSchema(db);
  const res = await db.query<{ id: string; label: string; created_by: string; created_at: Date }>(
    `SELECT id, label, created_by, created_at
       FROM provider_backups
      WHERE provider_id = $1
      ORDER BY created_at DESC
      LIMIT 50`,
    [providerId],
  );
  return res.rows.map((r) => ({
    id: r.id,
    label: r.label,
    createdBy: r.created_by,
    createdAt: r.created_at instanceof Date ? r.created_at.toISOString() : String(r.created_at),
  }));
}

export async function createProviderBackup(
  db: SqlQueryable,
  providerId: string,
  createdBy: string,
  label = "",
): Promise<{ id: string; createdAt: string }> {
  const provider = await getProviderRow(db, providerId);
  if (!provider) throw new Error("Provedor não encontrado.");
  const id = randomUUID().replace(/-/g, "").slice(0, 16);
  const res = await db.query<{ created_at: Date }>(
    `INSERT INTO provider_backups (id, provider_id, label, created_by, snapshot, created_at)
     VALUES ($1, $2, $3, $4, $5::jsonb, NOW())
     RETURNING created_at`,
    [id, providerId, label || `Backup ${new Date().toISOString().slice(0, 16)}`, createdBy, JSON.stringify(provider.data)],
  );
  return {
    id,
    createdAt: res.rows[0].created_at instanceof Date ? res.rows[0].created_at.toISOString() : new Date().toISOString(),
  };
}

export async function getProviderBackup(db: SqlQueryable, providerId: string, backupId: string) {
  await ensureCoreSchema(db);
  const res = await db.query<{ id: string; snapshot: Record<string, unknown> }>(
    `SELECT id, snapshot FROM provider_backups WHERE id = $1 AND provider_id = $2 LIMIT 1`,
    [backupId, providerId],
  );
  return res.rows[0] || null;
}

export async function deleteProviderBackup(db: SqlQueryable, providerId: string, backupId: string): Promise<boolean> {
  await ensureCoreSchema(db);
  const res = await db.query(`DELETE FROM provider_backups WHERE id = $1 AND provider_id = $2`, [backupId, providerId]);
  return (res.rowCount || 0) > 0;
}

function mergeDeep(base: Record<string, unknown>, patch: Record<string, unknown>): Record<string, unknown> {
  const out: Record<string, unknown> = { ...base };
  for (const [key, value] of Object.entries(patch)) {
    if (value !== null && typeof value === "object" && !Array.isArray(value) &&
        out[key] !== null && typeof out[key] === "object" && !Array.isArray(out[key])) {
      out[key] = mergeDeep(out[key] as Record<string, unknown>, value as Record<string, unknown>);
    } else {
      out[key] = value;
    }
  }
  return out;
}

export function getStoreDb(): SqlQueryable | null {
  return getPgPool();
}
