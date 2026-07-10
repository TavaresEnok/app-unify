import { FUNCTION_REQUEST_TYPES } from "./contracts";
import { handlers } from "./handlers";

describe("function request handlers", () => {
  it("registers exactly one handler for every shared request type", () => {
    expect(Object.keys(handlers).sort()).toEqual([...FUNCTION_REQUEST_TYPES].sort());
    expect(Object.values(handlers).every((handler) => typeof handler === "function")).toBe(true);
  });
});
