#!/usr/bin/env node
import { createRequire } from 'node:module';
import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';

const require = createRequire(import.meta.url);

function loadModule(candidates) {
  for (const candidate of candidates) {
    try {
      return require(candidate);
    } catch {
      // Try next candidate
    }
  }
  throw new Error(`Unable to resolve module from: ${candidates.join(', ')}`);
}

const { Pool } = loadModule(['pg', '/app/node_modules/pg', '../../api-service/node_modules/pg']);
const { CORE_SCHEMA_STATEMENTS } = loadModule([
  '/app/dist/services/core-schema-ddl.js',
  '../../shared/runtime/core-schema-ddl.js',
  '../../api-service/dist/services/core-schema-ddl.js',
]);
const { encryptSecret, hashPassword } = loadModule([
  '/app/dist/services/self-auth.js',
  '../../shared/runtime/self-auth.js',
  '../../api-service/dist/services/self-auth.js',
]);

let adminSdk = null;
try {
  adminSdk = loadModule(['firebase-admin', '/app/node_modules/firebase-admin', '../../api-service/node_modules/firebase-admin']);
} catch {
  adminSdk = null;
}

const SENSITIVE_KEYS = new Set([
  'apiToken',
  'sgpToken',
  'appName',
  'systemUrl',
  'sgpBaseUrl',
  'acsPassword',
  'acsApiKey',
  'acsUsername',
]);

function stripSecretsFromPublicData(obj) {
  if (!obj || typeof obj !== 'object' || Array.isArray(obj)) return {};
  const clone = structuredClone(obj);
  if (clone.details && typeof clone.details === 'object') {
    for (const k of SENSITIVE_KEYS) delete clone.details[k];
  }
  if (clone.integrations && typeof clone.integrations === 'object') {
    const erp = clone.integrations.erp;
    clone.integrations = erp ? { erp } : {};
  }
  if (clone.config?.integrations && typeof clone.config.integrations === 'object') {
    const erp = clone.config.integrations.erp;
    clone.config.integrations = erp ? { erp } : {};
  }
  for (const k of SENSITIVE_KEYS) delete clone[k];
  return clone;
}

function generateStrongPassword() {
  return crypto.randomBytes(24).toString('base64url').slice(0, 24);
}

function initFirestoreIfConfigured() {
  const credPath = process.env.GOOGLE_APPLICATION_CREDENTIALS?.trim();
  if (!adminSdk || !credPath || !fs.existsSync(credPath)) {
    return null;
  }
  if (!adminSdk.apps.length) {
    adminSdk.initializeApp({
      credential: adminSdk.credential.cert(JSON.parse(fs.readFileSync(credPath, 'utf8'))),
    });
  }
  return adminSdk.firestore();
}

async function migrateFirestore(pool, db) {
  let providerCount = 0;
  let backupCount = 0;
  let auditCount = 0;

  if (!db) {
    return { providerCount, backupCount, auditCount, skippedFirestore: true };
  }

  const provSnap = await db.collection('provedores').get();
  for (const doc of provSnap.docs) {
    const id = doc.id;
    const rawData = doc.data() || {};
    const name = String(rawData.name || id);
    const active = rawData.active !== false;
    const cleanData = stripSecretsFromPublicData(rawData);

    await pool.query(
      `INSERT INTO providers (id, name, active, data, created_at, updated_at)
       VALUES ($1, $2, $3, $4::jsonb, NOW(), NOW())
       ON CONFLICT (id) DO UPDATE SET
         name = EXCLUDED.name,
         active = EXCLUDED.active,
         data = providers.data || EXCLUDED.data,
         updated_at = NOW()`,
      [id, name, active, JSON.stringify(cleanData)],
    );
    providerCount++;

    const [sgpSecretDoc, acsSecretDoc] = await Promise.all([
      doc.ref.collection('secrets').doc('sgp').get(),
      doc.ref.collection('secrets').doc('acs').get(),
    ]);

    if (sgpSecretDoc.exists) {
      const secretPayload = sgpSecretDoc.data()?.integrations || sgpSecretDoc.data();
      if (secretPayload && typeof secretPayload === 'object') {
        await pool.query(
          `INSERT INTO provider_secrets (provider_id, kind, ciphertext, updated_at)
           VALUES ($1, 'erp', $2, NOW())
           ON CONFLICT (provider_id, kind) DO UPDATE SET
             ciphertext = EXCLUDED.ciphertext,
             updated_at = NOW()`,
          [id, encryptSecret(JSON.stringify(secretPayload))],
        );
      }
    }

    if (acsSecretDoc.exists) {
      const acsPayload = acsSecretDoc.data();
      if (acsPayload && typeof acsPayload === 'object') {
        await pool.query(
          `INSERT INTO provider_secrets (provider_id, kind, ciphertext, updated_at)
           VALUES ($1, 'acs', $2, NOW())
           ON CONFLICT (provider_id, kind) DO UPDATE SET
             ciphertext = EXCLUDED.ciphertext,
             updated_at = NOW()`,
          [id, encryptSecret(JSON.stringify(acsPayload))],
        );
      }
    }

    const backupsSnap = await doc.ref.collection('migration_backups').get();
    for (const bDoc of backupsSnap.docs) {
      const bData = bDoc.data() || {};
      const snapshot = bData.snapshot || bData.data || bData;
      const createdAt = bData.createdAt?.toDate ? bData.createdAt.toDate() : new Date();
      await pool.query(
        `INSERT INTO provider_backups (id, provider_id, label, created_by, snapshot, created_at)
         VALUES ($1, $2, $3, $4, $5::jsonb, $6)
         ON CONFLICT (id) DO NOTHING`,
        [
          bDoc.id,
          id,
          String(bData.label || 'Migrated backup'),
          String(bData.createdBy || 'migration'),
          JSON.stringify(snapshot),
          createdAt,
        ],
      );
      backupCount++;
    }
  }

  const auditSnap = await db.collection('audit_logs').limit(500).get();
  for (const aDoc of auditSnap.docs) {
    const a = aDoc.data() || {};
    const existing = await pool.query(
      `SELECT 1 FROM audit_logs WHERE correlation_id = $1 LIMIT 1`,
      [`fs:${aDoc.id}`],
    );
    if (existing.rows.length) continue;

    const createdAt = a.createdAt?.toDate ? a.createdAt.toDate() : new Date();
    await pool.query(
      `INSERT INTO audit_logs (type, requester_uid, provider_id, correlation_id, payload, source, outcome, created_at)
       VALUES ($1, $2, $3, $4, $5::jsonb, $6, $7, $8)`,
      [
        String(a.type || 'MIGRATED_EVENT'),
        String(a.requesterUid || 'system'),
        a.providerId ? String(a.providerId) : null,
        `fs:${aDoc.id}`,
        JSON.stringify(a.payload || {}),
        String(a.source || 'firestore-migration'),
        String(a.outcome || 'success'),
        createdAt,
      ],
    );
    auditCount++;
  }

  return { providerCount, backupCount, auditCount, skippedFirestore: false };
}

async function seedAdminUsers(pool) {
  const admins = [
    {
      uid: '1xxT2DJuNxV4nqi0JypcukqcNuj1',
      email: 'tavares.enok@gmail.com',
      role: 'superAdmin',
      providerId: null,
    },
    {
      uid: 'IUKrFxSHvCV7GusbWb3Etsk76s23',
      email: 'vibe@gmail.com',
      role: 'providerAdmin',
      providerId: 'vibe',
    },
  ];

  const created = [];
  for (const admin of admins) {
    const password = generateStrongPassword();
    const passwordHash = hashPassword(password);
    const res = await pool.query(
      `INSERT INTO admin_users (uid, email, password_hash, role, provider_id, disabled, token_version, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, FALSE, 1, NOW(), NOW())
       ON CONFLICT (uid) DO NOTHING
       RETURNING uid, email, role, provider_id`,
      [admin.uid, admin.email.toLowerCase(), passwordHash, admin.role, admin.providerId],
    );
    if (res.rows.length > 0) {
      created.push({
        email: admin.email,
        role: admin.role,
        providerId: admin.providerId || 'global',
        password,
      });
    }
  }

  const outPath = process.env.ADMIN_PASSWORDS_OUT?.trim();
  if (created.length > 0 && outPath) {
    fs.mkdirSync(path.dirname(outPath), { recursive: true });
    const lines = [
      `# Credenciais iniciais geradas em ${new Date().toISOString()} (alterar após primeiro login)`,
      ...created.map((c) => `${c.email} | role=${c.role} | provider=${c.providerId} | password=${c.password}`),
      '',
    ];
    fs.writeFileSync(outPath, lines.join('\n'), { mode: 0o600 });
    fs.chmodSync(outPath, 0o600);
  }

  return created.map((c) => c.email);
}

async function registerUpConnect(pool) {
  const ixcUrl = (process.env.UPCONNECT_IXC_URL || 'https://ixc.upconnectfibra.com.br').trim().replace(/\/+$/, '');
  const ixcToken = (process.env.UPCONNECT_IXC_TOKEN || '').trim();

  const publicData = {
    name: 'UP Connect',
    active: true,
    layoutType: 'layout_05',
    themeColor: '#0EA5E9',
    integrations: { erp: 'ixc' },
    features: {
      financeiro: true,
      consumo: true,
      diagnostico: true,
      suporte: true,
      wifi: false,
      tr069: false,
    },
    details: {
      systemUrl: ixcUrl,
    },
  };

  await pool.query(
    `INSERT INTO providers (id, name, active, data, created_at, updated_at)
     VALUES ('upconnect', 'UP Connect', TRUE, $1::jsonb, NOW(), NOW())
     ON CONFLICT (id) DO UPDATE SET
       name = EXCLUDED.name,
       active = EXCLUDED.active,
       data = providers.data || EXCLUDED.data,
       updated_at = NOW()`,
    [JSON.stringify(publicData)],
  );

  let secretSaved = false;
  if (ixcToken) {
    const secretPayload = {
      erp: 'ixc',
      sgpBaseUrl: ixcUrl,
      apiToken: ixcToken,
    };
    await pool.query(
      `INSERT INTO provider_secrets (provider_id, kind, ciphertext, updated_at)
       VALUES ('upconnect', 'erp', $1, NOW())
       ON CONFLICT (provider_id, kind) DO UPDATE SET
         ciphertext = EXCLUDED.ciphertext,
         updated_at = NOW()`,
      [encryptSecret(JSON.stringify(secretPayload))],
    );
    secretSaved = true;
  }

  return { registered: true, secretSaved, ixcUrl };
}

async function main() {
  const databaseUrl = process.env.DATABASE_URL?.trim();
  if (!databaseUrl) {
    throw new Error('DATABASE_URL não definida.');
  }
  const pool = new Pool({ connectionString: databaseUrl });
  try {
    for (const stmt of CORE_SCHEMA_STATEMENTS) {
      await pool.query(stmt);
    }

    const db = initFirestoreIfConfigured();
    const firestoreSummary = await migrateFirestore(pool, db);
    const seededAdmins = await seedAdminUsers(pool);
    const upConnectSummary = await registerUpConnect(pool);

    console.log(JSON.stringify({
      ok: true,
      firestore: firestoreSummary,
      seededAdminsCount: seededAdmins.length,
      seededAdminsEmails: seededAdmins,
      upconnect: upConnectSummary,
    }));
  } finally {
    await pool.end();
  }
}

main().catch((err) => {
  console.error('[migration] erro:', err?.message || err);
  process.exit(1);
});
