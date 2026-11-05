import { expect, it } from "vitest";
import { mapWithConcurrency } from "./boundedWork";
it("bounds contract fan-out and preserves contract order", async () => {
  let active = 0, peak = 0;
  const values = Array.from({ length: 20 }, (_, index) => index);
  const result = await mapWithConcurrency(values, 2, async value => {
    active++; peak = Math.max(peak, active);
    await new Promise(resolve => setTimeout(resolve, value % 3));
    active--; return value * 2;
  });
  expect(result).toEqual(values.map(value => value * 2));
  expect(peak).toBe(2);
});
