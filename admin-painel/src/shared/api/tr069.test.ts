import { describe, expect, it } from "vitest";
import { cpeActionAvailability, driverSupportsFeature, type AdminCpeOverviewResponse } from "./tr069";

const overview = { online: null } as unknown as AdminCpeOverviewResponse["overview"];
const base = (patch: Partial<AdminCpeOverviewResponse>): AdminCpeOverviewResponse => ({ enabled: true, driver: "genieacs", overview, hosts: [], ...patch });

describe("TR-069 admin actions", () => {
  it("hides actions the SGP CPE Manager cannot run, even without features", () => {
    expect(cpeActionAvailability(base({ driver: "sgp" }))).toEqual({ reboot: false, optimize: false, diagnostic: false });
    expect(driverSupportsFeature("sgp", "wifi")).toBe(true);
    expect(driverSupportsFeature("sgp", "guestWifi")).toBe(false);
  });

  it("follows the features sent by the server", () => {
    expect(cpeActionAvailability(base({ features: { reboot: true, channelOptimize: false, speedDiagnostic: true } }))).toEqual({ reboot: true, optimize: false, diagnostic: true });
    expect(cpeActionAvailability(base({ driver: "sgp", features: { reboot: true } })).reboot).toBe(false);
  });

  it("shows no actions in read-only mode or without a device", () => {
    expect(cpeActionAvailability(base({}), true)).toEqual({ reboot: false, optimize: false, diagnostic: false });
    expect(cpeActionAvailability(base({ overview: null }))).toEqual({ reboot: false, optimize: false, diagnostic: false });
    expect(cpeActionAvailability(null)).toEqual({ reboot: false, optimize: false, diagnostic: false });
  });
});
