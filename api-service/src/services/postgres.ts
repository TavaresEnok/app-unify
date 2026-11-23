import { Pool, type QueryResult, type QueryResultRow } from "pg";
import {
  SUBSCRIBER_SEGMENTS_INDEXES_SQL,
  SUBSCRIBER_SEGMENTS_TABLE_SQL,
} from "./subscriber-segments-ddl";

export interface SqlQueryable {
  query<R extends QueryResultRow = any>(text: string, values?: unknown[]): Promise<QueryResult<R>>;
}

let poolInstance: Pool | null = null;
let schemaReady: Promise<void> | null = null;

export function getPgPool(): Pool | null {
  if (poolInstance) return poolInstance;
  const connectionString = process.env.DATABASE_URL?.trim();
  if (!connectionString) return null;
  poolInstance = new Pool({
    connectionString,
    max: 10,
    idleTimeoutMillis: 30_000,
    connectionTimeoutMillis: 5_000,
  });
  poolInstance.on("error", (error) => {
    console.warn(JSON.stringify({ severity: "WARNING", message: "postgres.pool.error", error: error.message }));
  });
  return poolInstance;
}

export async function ensureNotificationSchema(db: SqlQueryable): Promise<void> {
  if (!schemaReady) {
    schemaReady = (async () => {
      await db.query(SUBSCRIBER_SEGMENTS_TABLE_SQL);
      for (const idxSql of SUBSCRIBER_SEGMENTS_INDEXES_SQL) {
        await db.query(idxSql);
      }

      await db.query(`
        CREATE TABLE IF NOT EXISTS subscriber_devices (
          provider_id TEXT NOT NULL,
          cpfcnpj TEXT NOT NULL,
          auth_uid TEXT NOT NULL DEFAULT '',
          fcm_token TEXT NOT NULL,
          contrato_id TEXT NOT NULL DEFAULT '',
          plano TEXT NOT NULL DEFAULT '',
          contract_status TEXT NOT NULL DEFAULT '',
          connection_status TEXT NOT NULL DEFAULT '',
          updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
          PRIMARY KEY (provider_id, cpfcnpj, fcm_token)
        )
      `);
      await db.query(`CREATE INDEX IF NOT EXISTS idx_devices_provider_cpf ON subscriber_devices (provider_id, cpfcnpj)`);

      await db.query(`
        CREATE TABLE IF NOT EXISTS notification_campaigns (
          id TEXT PRIMARY KEY,
          provider_id TEXT NOT NULL,
          title TEXT NOT NULL,
          body TEXT NOT NULL,
          category TEXT NOT NULL DEFAULT 'info',
          route TEXT NOT NULL DEFAULT '',
          filters JSONB NOT NULL DEFAULT '{}'::jsonb,
          matched_subscribers INTEGER NOT NULL DEFAULT 0,
          targeted_devices INTEGER NOT NULL DEFAULT 0,
          success_count INTEGER NOT NULL DEFAULT 0,
          failure_count INTEGER NOT NULL DEFAULT 0,
          delivery_mode TEXT NOT NULL DEFAULT 'multicast',
          sent_by TEXT NOT NULL DEFAULT '',
          created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        )
      `);
      await db.query(`CREATE INDEX IF NOT EXISTS idx_campaigns_provider_created ON notification_campaigns (provider_id, created_at DESC)`);

      await db.query(`
        CREATE TABLE IF NOT EXISTS diagnostic_results (
          id TEXT PRIMARY KEY,
          provider_id TEXT NOT NULL,
          cpfcnpj TEXT NOT NULL,
          contrato_id TEXT NOT NULL DEFAULT '',
          client_name TEXT NOT NULL DEFAULT '',
          plan_name TEXT NOT NULL DEFAULT '',
          mode TEXT NOT NULL DEFAULT 'quick',
          verdict TEXT NOT NULL DEFAULT 'unknown',
          verdict_headline TEXT NOT NULL DEFAULT '',
          cause TEXT NOT NULL DEFAULT '',
          summary JSONB NOT NULL DEFAULT '{}'::jsonb,
          olt_name TEXT NOT NULL DEFAULT '',
          bairro TEXT NOT NULL DEFAULT '',
          cidade TEXT NOT NULL DEFAULT '',
          created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        )
      `);
      await db.query(`CREATE INDEX IF NOT EXISTS idx_diag_results_provider_created ON diagnostic_results (provider_id, created_at DESC)`);

      await db.query(`
        DO $$
        BEGIN
          IF to_regclass('public.sgp_clients') IS NOT NULL THEN
            ALTER TABLE sgp_clients ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
            CREATE INDEX IF NOT EXISTS sgp_clients_cpf ON sgp_clients (provider_id, cpfcnpj);
          END IF;
        END $$;
      `);
    })().catch((error) => {
      schemaReady = null;
      throw error;
    });
  }
  return schemaReady;
}

export function resetPgSchemaForTests(): void {
  schemaReady = null;
}

