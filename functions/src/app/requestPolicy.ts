import type { FunctionRequest, FunctionRequestType } from "../contracts";
export type ReplayPolicy = "read" | "uncertain-effect";
// Stable IDs alone do not prove replay safety across partial completion and concurrent edits.
export const REQUEST_POLICIES = {
  UPDATE_PROVIDER_CONFIG: "uncertain-effect", UPDATE_PROVIDER_DETAILS: "uncertain-effect",
  CREATE_PROVIDER: "uncertain-effect", DELETE_PROVIDER: "uncertain-effect",
  GET_DASHBOARD_DATA: "read", GET_PROVIDER_DASHBOARD_DATA: "read",
  SEND_PUSH_NOTIFICATION: "uncertain-effect", SEND_SCOPED_NOTIFICATION: "uncertain-effect",
  SEND_SCOPED_NOTIFICATION_SEGMENTED: "uncertain-effect", SGP_API_PROXY: "uncertain-effect",
  GET_ALL_TICKETS: "read", GET_PROVIDER_TICKETS: "read", CREATE_TICKET: "uncertain-effect",
  REPLY_TO_TICKET: "uncertain-effect", UPDATE_TICKET_STATUS: "uncertain-effect", DELETE_TICKET: "uncertain-effect",
  LIST_ADMIN_USERS: "read", CREATE_ADMIN_USER: "uncertain-effect", DELETE_ADMIN_USER: "uncertain-effect",
  SET_SUPER_ADMIN_BY_EMAIL: "uncertain-effect", LIST_PROVIDER_CLIENTS: "read", GET_CLIENT_DETAILS: "read",
  DELETE_CLIENT: "uncertain-effect", BACKUP_PROVIDER_CONFIG: "uncertain-effect", LIST_PROVIDER_BACKUPS: "read",
  RESTORE_PROVIDER_CONFIG: "uncertain-effect", DELETE_PROVIDER_BACKUP: "uncertain-effect",
} satisfies Record<FunctionRequestType, ReplayPolicy>;
export function replayPolicy(request: FunctionRequest): ReplayPolicy {
  if (!Object.prototype.hasOwnProperty.call(REQUEST_POLICIES, request.type)) throw new Error("Unsupported RPC command");
  if (request.type === "SGP_API_PROXY" && "action" in request.payload &&
      ["get", "get_single", "status"].includes(String(request.payload.action))) return "read";
  return REQUEST_POLICIES[request.type];
}
