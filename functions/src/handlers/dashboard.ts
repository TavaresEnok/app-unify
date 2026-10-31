import type { RequestHandler } from "../app/request";
import { db } from "../app/firebase";
import { requireProviderAccess, requireSuperAdmin } from "../app/permissions";
import { loadGlobalDashboard, loadProviderDashboard } from "../app/dashboardData";

export const getDashboardData: RequestHandler<"GET_DASHBOARD_DATA"> = async ({ requesterUid }) => {
  await requireSuperAdmin(requesterUid);
  return loadGlobalDashboard(db);
};

export const getProviderDashboardData: RequestHandler<"GET_PROVIDER_DASHBOARD_DATA"> = async ({ requesterUid, payload }) => {
  await requireProviderAccess(requesterUid, payload.providerId);
  return loadProviderDashboard(db, payload.providerId);
};
