import type { HandlerRegistry } from "../app/requestRouter";
import {
  createProvider,
  deleteProvider,
  updateProviderConfig,
  updateProviderDetails,
} from "./providers";
import { getDashboardData, getProviderDashboardData } from "./dashboard";
import {
  sendPushNotification,
  sendScopedNotification,
  sendSegmentedNotification,
} from "./notifications";
import { sgpApiProxy } from "./sgp";
import {
  createTicket,
  deleteTicket,
  getAllTickets,
  getProviderTickets,
  replyToTicket,
  updateTicketStatus,
} from "./tickets";
import {
  createAdminUser,
  deleteAdminUser,
  listAdminUsers,
  setSuperAdminByEmail,
} from "./users";
import { deleteClient, getClientDetails, listProviderClients } from "./clients";
import {
  backupProviderConfig,
  deleteProviderBackup,
  listProviderBackups,
  restoreProviderConfig,
} from "./backups";

export const handlers = {
  UPDATE_PROVIDER_CONFIG: updateProviderConfig,
  UPDATE_PROVIDER_DETAILS: updateProviderDetails,
  CREATE_PROVIDER: createProvider,
  DELETE_PROVIDER: deleteProvider,
  GET_DASHBOARD_DATA: getDashboardData,
  GET_PROVIDER_DASHBOARD_DATA: getProviderDashboardData,
  SEND_PUSH_NOTIFICATION: sendPushNotification,
  SEND_SCOPED_NOTIFICATION: sendScopedNotification,
  SEND_SCOPED_NOTIFICATION_SEGMENTED: sendSegmentedNotification,
  SGP_API_PROXY: sgpApiProxy,
  GET_ALL_TICKETS: getAllTickets,
  GET_PROVIDER_TICKETS: getProviderTickets,
  CREATE_TICKET: createTicket,
  REPLY_TO_TICKET: replyToTicket,
  UPDATE_TICKET_STATUS: updateTicketStatus,
  DELETE_TICKET: deleteTicket,
  LIST_ADMIN_USERS: listAdminUsers,
  CREATE_ADMIN_USER: createAdminUser,
  DELETE_ADMIN_USER: deleteAdminUser,
  SET_SUPER_ADMIN_BY_EMAIL: setSuperAdminByEmail,
  LIST_PROVIDER_CLIENTS: listProviderClients,
  GET_CLIENT_DETAILS: getClientDetails,
  DELETE_CLIENT: deleteClient,
  BACKUP_PROVIDER_CONFIG: backupProviderConfig,
  LIST_PROVIDER_BACKUPS: listProviderBackups,
  RESTORE_PROVIDER_CONFIG: restoreProviderConfig,
  DELETE_PROVIDER_BACKUP: deleteProviderBackup,
} satisfies HandlerRegistry;
