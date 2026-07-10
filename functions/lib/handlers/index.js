"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.handlers = void 0;
const providers_1 = require("./providers");
const dashboard_1 = require("./dashboard");
const notifications_1 = require("./notifications");
const sgp_1 = require("./sgp");
const tickets_1 = require("./tickets");
const users_1 = require("./users");
const clients_1 = require("./clients");
const backups_1 = require("./backups");
exports.handlers = {
    UPDATE_PROVIDER_CONFIG: providers_1.updateProviderConfig,
    UPDATE_PROVIDER_DETAILS: providers_1.updateProviderDetails,
    CREATE_PROVIDER: providers_1.createProvider,
    DELETE_PROVIDER: providers_1.deleteProvider,
    GET_DASHBOARD_DATA: dashboard_1.getDashboardData,
    GET_PROVIDER_DASHBOARD_DATA: dashboard_1.getProviderDashboardData,
    SEND_PUSH_NOTIFICATION: notifications_1.sendPushNotification,
    SEND_SCOPED_NOTIFICATION: notifications_1.sendScopedNotification,
    SEND_SCOPED_NOTIFICATION_SEGMENTED: notifications_1.sendSegmentedNotification,
    SGP_API_PROXY: sgp_1.sgpApiProxy,
    GET_ALL_TICKETS: tickets_1.getAllTickets,
    GET_PROVIDER_TICKETS: tickets_1.getProviderTickets,
    CREATE_TICKET: tickets_1.createTicket,
    REPLY_TO_TICKET: tickets_1.replyToTicket,
    UPDATE_TICKET_STATUS: tickets_1.updateTicketStatus,
    DELETE_TICKET: tickets_1.deleteTicket,
    LIST_ADMIN_USERS: users_1.listAdminUsers,
    CREATE_ADMIN_USER: users_1.createAdminUser,
    DELETE_ADMIN_USER: users_1.deleteAdminUser,
    SET_SUPER_ADMIN_BY_EMAIL: users_1.setSuperAdminByEmail,
    LIST_PROVIDER_CLIENTS: clients_1.listProviderClients,
    GET_CLIENT_DETAILS: clients_1.getClientDetails,
    DELETE_CLIENT: clients_1.deleteClient,
    BACKUP_PROVIDER_CONFIG: backups_1.backupProviderConfig,
    LIST_PROVIDER_BACKUPS: backups_1.listProviderBackups,
    RESTORE_PROVIDER_CONFIG: backups_1.restoreProviderConfig,
    DELETE_PROVIDER_BACKUP: backups_1.deleteProviderBackup,
};
//# sourceMappingURL=index.js.map