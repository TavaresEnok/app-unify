// Generated from shared/contracts/index.ts. Do not edit directly.
/**
 * Canonical contracts shared by the admin panel, Functions and REST API.
 * Run `npm run contracts:sync` after changing this file.
 */

export type UserRole = "superAdmin" | "providerAdmin" | "client";

export interface UserClaims {
  superAdmin?: boolean;
  providerId?: string;
  role?: UserRole;
}

export type LayoutType =
  | "layout_02"
  | "layout_03"
  | "layout_04"
  | "layout_05"
  | "layout_06";

export type DiagnosticStyle =
  | "default"
  | "diagnostic_02"
  | "diagnostic_03"
  | "diagnostic_05"
  | "diagnostic_06"
  | "diagnostic_07";

export interface TypographyConfig {
  fontFamily: string;
  titleSize: "small" | "medium" | "large";
  bodySize: "small" | "medium" | "large";
  fontWeight: "regular" | "medium" | "semibold" | "bold";
}

export interface MenuItemConfig {
  enabled: boolean;
  name: string;
  icon?: string;
}

export interface MenuConfig {
  order: string[];
  items: Record<string, MenuItemConfig>;
}

export interface ProviderConfig {
  layoutType: LayoutType;
  diagnosticStyle?: DiagnosticStyle;
  themeColor: string;
  secondaryColor: string;
  backgroundColor?: string;
  cardColor?: string;
  cardTextColor?: string;
  textColor?: string;
  textSecondaryColor?: string;
  iconColor?: string;
  actionColor?: string;
  invoiceColor?: string;
  quickActionsCardColor?: string;
  quickActionsTextColor?: string;
  otherCardsColor?: string;
  otherCardsTextColor?: string;
  typography?: TypographyConfig;
  logoUrl?: string;
  iconUrl?: string;
  backgroundUrl?: string;
  loginQuote?: string;
  termsOfUse?: string;
  imageCarousel?: any[];
  menuConfig?: MenuConfig;
  supportContacts?: any[];
  supportChannels?: any[];
  strings?: Record<string, any>;
  other?: Record<string, any>;
  social?: Record<string, any>;
  socialNetworks?: Record<string, any>;
  messages?: Record<string, any>;
  integrations?: Record<string, any>;
  faq?: any[];
  tips?: any[];
  features?: Record<string, boolean>;
  splash?: Record<string, any>;
  login?: Record<string, any>;
  notifications?: Record<string, any>;
  promotions?: Record<string, any>;
  dashboardConfig?: Record<string, any>;
  /** @deprecated Read compatibility for configurations saved before dashboardConfig. */
  dashboard?: Record<string, any>;
  appVersion?: {
    minVersion?: string;
    latestVersion?: string;
    forceUpdate?: boolean;
    updateMessage?: {
      pt_BR: { title: string; message: string; buttonText: string };
    };
    storeUrls?: { android?: string; ios?: string };
  };
  [key: string]: any;
}

export interface Provider {
  id: string;
  name: string;
  active?: boolean;
  apiUrl?: string;
  config?: Partial<ProviderConfig>;
  [key: string]: unknown;
}

export interface AdminUser {
  uid: string;
  email?: string;
  superAdmin: boolean;
  providerId?: string;
}

export type TicketStatus = "Aberto" | "Em Andamento" | "Fechado";

export interface Ticket {
  id: string;
  subject: string;
  status: TicketStatus;
  providerId: string;
  providerName?: string;
  userEmail?: string;
  createdByUid?: string;
  createdAt?: unknown;
  updatedAt?: unknown;
}

export interface TicketMessage {
  id: string;
  message: string;
  senderUid: string;
  senderEmail?: string;
  senderRole?: UserRole;
  imageUrl?: string | null;
  createdAt?: unknown;
}

export interface Client {
  id: string;
  providerId: string;
  nome?: string;
  cpfCnpj?: string;
  plano?: string;
  status?: string;
  [key: string]: unknown;
}

export interface Notification {
  id: string;
  title: string;
  message: string;
  providerId?: string;
  createdAt?: unknown;
}

export interface SgpApiProxyResult {
  clientes?: Client[];
  paginacao?: { total: number; limit: number; offset: number };
  count?: number;
  message?: string;
  [key: string]: any;
}

export interface FunctionRequestPayloadMap {
  UPDATE_PROVIDER_CONFIG: { providerId: string; config: Partial<ProviderConfig> };
  UPDATE_PROVIDER_DETAILS: { providerId: string; details: Record<string, unknown> };
  CREATE_PROVIDER: { providerId: string; name: string };
  DELETE_PROVIDER: { providerId: string };
  GET_DASHBOARD_DATA: Record<string, never>;
  GET_PROVIDER_DASHBOARD_DATA: { providerId: string };
  SEND_PUSH_NOTIFICATION: {
    title: string;
    body: string;
    providerId?: string;
    category?: string;
    targetAll?: boolean;
    targetCpf?: string;
    route?: string;
  };
  SEND_SCOPED_NOTIFICATION: {
    title: string;
    body: string;
    providerId?: string;
    category?: string;
    targetAll?: boolean;
    targetCpf?: string;
    route?: string;
  };
  SEND_SCOPED_NOTIFICATION_SEGMENTED: {
    title: string;
    body: string;
    providerId: string | null;
    statusFilter?: string;
    planFilter?: string;
  };
  SGP_API_PROXY: {
    providerId: string;
    action: "sync" | "get" | "get_single";
    params?: Record<string, unknown>;
  };
  GET_ALL_TICKETS: Record<string, never>;
  GET_PROVIDER_TICKETS: { providerId: string };
  CREATE_TICKET: {
    subject: string;
    message: string;
    providerId: string;
    providerName?: string;
    userEmail?: string | null;
    imageUrl?: string | null;
  };
  REPLY_TO_TICKET: { ticketId: string; message: string; imageUrl?: string | null };
  UPDATE_TICKET_STATUS: { ticketId: string; status: TicketStatus };
  DELETE_TICKET: { ticketId: string };
  LIST_ADMIN_USERS: Record<string, never>;
  CREATE_ADMIN_USER: {
    email: string;
    password: string;
    role: "superAdmin" | "providerAdmin";
    providerId?: string;
  };
  DELETE_ADMIN_USER: { uid: string };
  SET_SUPER_ADMIN_BY_EMAIL: { email: string };
  LIST_PROVIDER_CLIENTS: { providerId: string };
  GET_CLIENT_DETAILS: { providerId: string; clientId: string };
  DELETE_CLIENT: { providerId: string; clientId: string };
  BACKUP_PROVIDER_CONFIG: { providerId: string; name?: string };
  LIST_PROVIDER_BACKUPS: { providerId: string };
  RESTORE_PROVIDER_CONFIG: { providerId: string; backupId: string };
  DELETE_PROVIDER_BACKUP: { providerId: string; backupId: string };
}

export type FunctionRequestType = keyof FunctionRequestPayloadMap;

export interface FunctionResultMap {
  UPDATE_PROVIDER_CONFIG: { success: true; message: string; providerId: string };
  UPDATE_PROVIDER_DETAILS: { success: true; message: string; providerId: string };
  CREATE_PROVIDER: { success: true; message: string; providerId: string };
  DELETE_PROVIDER: { success: true; message: string };
  GET_DASHBOARD_DATA: Record<string, unknown>;
  GET_PROVIDER_DASHBOARD_DATA: Record<string, unknown>;
  SEND_PUSH_NOTIFICATION: { success: true; message: string };
  SEND_SCOPED_NOTIFICATION: { success: true; message: string };
  SEND_SCOPED_NOTIFICATION_SEGMENTED: { success: true; message: string };
  SGP_API_PROXY: SgpApiProxyResult;
  GET_ALL_TICKETS: Ticket[];
  GET_PROVIDER_TICKETS: Ticket[];
  CREATE_TICKET: { success: true; message: string; ticketId: string };
  REPLY_TO_TICKET: { success: true; message: string };
  UPDATE_TICKET_STATUS: { success: true; message: string };
  DELETE_TICKET: { success: true; message: string };
  LIST_ADMIN_USERS: AdminUser[];
  CREATE_ADMIN_USER: { success: true; message: string; uid: string };
  DELETE_ADMIN_USER: { success: true; message: string };
  SET_SUPER_ADMIN_BY_EMAIL: { success: true; message: string; uid: string };
  LIST_PROVIDER_CLIENTS: Client[];
  GET_CLIENT_DETAILS: Client;
  DELETE_CLIENT: { success: true; message: string };
  BACKUP_PROVIDER_CONFIG: { success: true; message: string; backupId: string };
  LIST_PROVIDER_BACKUPS: Array<Record<string, unknown>>;
  RESTORE_PROVIDER_CONFIG: { success: true; message: string };
  DELETE_PROVIDER_BACKUP: { success: true; message: string };
}

export interface FunctionRequest<T extends FunctionRequestType = FunctionRequestType> {
  type: T;
  requesterUid: string;
  payload: FunctionRequestPayloadMap[T];
  createdAt?: unknown;
}

export interface FunctionResponse<T extends FunctionRequestType = FunctionRequestType> {
  result?: FunctionResultMap[T];
  error?: string;
  code?: ErrorCode;
  requesterUid?: string | null;
  completedAt?: unknown;
}

export type ErrorCode =
  | "unauthenticated"
  | "permission-denied"
  | "invalid-argument"
  | "not-found"
  | "conflict"
  | "internal"
  | "timeout";

export const FUNCTION_REQUEST_TYPES = [
  "UPDATE_PROVIDER_CONFIG",
  "UPDATE_PROVIDER_DETAILS",
  "CREATE_PROVIDER",
  "DELETE_PROVIDER",
  "GET_DASHBOARD_DATA",
  "GET_PROVIDER_DASHBOARD_DATA",
  "SEND_PUSH_NOTIFICATION",
  "SEND_SCOPED_NOTIFICATION",
  "SEND_SCOPED_NOTIFICATION_SEGMENTED",
  "SGP_API_PROXY",
  "GET_ALL_TICKETS",
  "GET_PROVIDER_TICKETS",
  "CREATE_TICKET",
  "REPLY_TO_TICKET",
  "UPDATE_TICKET_STATUS",
  "DELETE_TICKET",
  "LIST_ADMIN_USERS",
  "CREATE_ADMIN_USER",
  "DELETE_ADMIN_USER",
  "SET_SUPER_ADMIN_BY_EMAIL",
  "LIST_PROVIDER_CLIENTS",
  "GET_CLIENT_DETAILS",
  "DELETE_CLIENT",
  "BACKUP_PROVIDER_CONFIG",
  "LIST_PROVIDER_BACKUPS",
  "RESTORE_PROVIDER_CONFIG",
  "DELETE_PROVIDER_BACKUP",
] as const satisfies readonly FunctionRequestType[];

export function isFunctionRequestType(value: unknown): value is FunctionRequestType {
  return typeof value === "string" &&
    (FUNCTION_REQUEST_TYPES as readonly string[]).includes(value);
}

export function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

export function requireString(
  value: unknown,
  field: string,
  options: { min?: number; max?: number } = {},
): string {
  if (typeof value !== "string") {
    throw new Error(`${field} deve ser uma string.`);
  }
  const normalized = value.trim();
  const min = options.min ?? 1;
  const max = options.max ?? 10_000;
  if (normalized.length < min || normalized.length > max) {
    throw new Error(`${field} deve ter entre ${min} e ${max} caracteres.`);
  }
  return normalized;
}

const REQUIRED_STRING_FIELDS: Partial<Record<FunctionRequestType, readonly string[]>> = {
  UPDATE_PROVIDER_CONFIG: ["providerId"],
  UPDATE_PROVIDER_DETAILS: ["providerId"],
  CREATE_PROVIDER: ["providerId", "name"],
  DELETE_PROVIDER: ["providerId"],
  GET_PROVIDER_DASHBOARD_DATA: ["providerId"],
  SEND_PUSH_NOTIFICATION: ["title", "body"],
  SEND_SCOPED_NOTIFICATION: ["title", "body"],
  SEND_SCOPED_NOTIFICATION_SEGMENTED: ["providerId", "title", "body"],
  SGP_API_PROXY: ["providerId", "action"],
  GET_PROVIDER_TICKETS: ["providerId"],
  CREATE_TICKET: ["subject", "message", "providerId"],
  REPLY_TO_TICKET: ["ticketId", "message"],
  UPDATE_TICKET_STATUS: ["ticketId", "status"],
  DELETE_TICKET: ["ticketId"],
  CREATE_ADMIN_USER: ["email", "password", "role"],
  DELETE_ADMIN_USER: ["uid"],
  SET_SUPER_ADMIN_BY_EMAIL: ["email"],
  LIST_PROVIDER_CLIENTS: ["providerId"],
  GET_CLIENT_DETAILS: ["providerId", "clientId"],
  DELETE_CLIENT: ["providerId", "clientId"],
  BACKUP_PROVIDER_CONFIG: ["providerId"],
  LIST_PROVIDER_BACKUPS: ["providerId"],
  RESTORE_PROVIDER_CONFIG: ["providerId", "backupId"],
  DELETE_PROVIDER_BACKUP: ["providerId", "backupId"],
};

export function validateFunctionPayload(type: FunctionRequestType, payload: unknown): void {
  if (!isRecord(payload)) throw new Error("payload deve ser um objeto.");
  for (const field of REQUIRED_STRING_FIELDS[type] || []) {
    requireString(payload[field], `payload.${field}`);
  }
  if (type === "UPDATE_PROVIDER_CONFIG" && !isRecord(payload.config)) {
    throw new Error("payload.config deve ser um objeto.");
  }
  if (type === "UPDATE_PROVIDER_DETAILS" && !isRecord(payload.details)) {
    throw new Error("payload.details deve ser um objeto.");
  }
  if (type === "CREATE_ADMIN_USER" && !["superAdmin", "providerAdmin"].includes(String(payload.role))) {
    throw new Error("payload.role invalido.");
  }
  if (type === "UPDATE_TICKET_STATUS" && !["Aberto", "Em Andamento", "Fechado"].includes(String(payload.status))) {
    throw new Error("payload.status invalido.");
  }
  if (type === "SGP_API_PROXY" && !["sync", "get", "get_single"].includes(String(payload.action))) {
    throw new Error("payload.action invalido.");
  }
}

export function assertFunctionRequest(value: unknown): asserts value is FunctionRequest {
  if (!isRecord(value)) throw new Error("Requisicao invalida.");
  if (!isFunctionRequestType(value.type)) throw new Error("Tipo de requisicao invalido.");
  requireString(value.requesterUid, "requesterUid", { max: 128 });
  validateFunctionPayload(value.type, value.payload);
}
