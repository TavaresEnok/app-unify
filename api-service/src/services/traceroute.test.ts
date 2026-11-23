import { EventEmitter } from "node:events";
import { PassThrough } from "node:stream";
import { afterEach, describe, expect, it, vi } from "vitest";
const mocks = vi.hoisted(() => ({ spawn: vi.fn() }));
vi.mock("node:child_process", () => ({ spawn: mocks.spawn }));
import { executeTraceroute } from "./traceroute";
import { parseTracerouteOutput } from "../validators/traceroute";

function processMock() {
  const child = Object.assign(new EventEmitter(), { stdout: new PassThrough(), kill: vi.fn() });
  mocks.spawn.mockReturnValue(child);
  return child;
}
afterEach(() => { vi.useRealTimers(); vi.clearAllMocks(); });
describe("bounded traceroute execution", () => {
  it("keeps unresponsive hops with one probe per hop", async () => {
    const child = processMock();
    const result = executeTraceroute("8.8.8.8", 15);
    child.stdout.write("traceroute to 8.8.8.8\n 1  *\n 2  8.8.8.8  3.5 ms\n");
    child.emit("close", 0);
    expect(mocks.spawn.mock.calls[0][1]).toEqual(["-n", "-q", "1", "-m", "15", "-w", "1", "8.8.8.8"]);
    const measured = await result;
    expect(measured.timedOut).toBe(false);
    expect(parseTracerouteOutput(measured.raw)).toEqual([
      { hop: 1, ip: "*", time: "*" }, { hop: 2, ip: "8.8.8.8", time: "3.5 ms" },
    ]);
  });
  it("returns partial measurements on deadline and kills the process", async () => {
    vi.useFakeTimers();
    const child = processMock();
    child.kill.mockImplementation(() => child.emit("close", null));
    const result = executeTraceroute("8.8.8.8", 30);
    child.stdout.write(" 1  1.1.1.1  2 ms\n");
    await vi.advanceTimersByTimeAsync(25_000);
    expect(child.kill).toHaveBeenCalledWith("SIGKILL");
    expect(await result).toEqual({ raw: " 1  1.1.1.1  2 ms\n", timedOut: true });
  });
  it("does not present command failure as a successful measurement", async () => {
    const child = processMock();
    const result = executeTraceroute("8.8.8.8", 15);
    child.emit("close", 1);
    await expect(result).rejects.toMatchObject({ status: 502 });
  });
});
