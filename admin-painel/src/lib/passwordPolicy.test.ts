import { expect, it } from "vitest";
import { changePasswordFormError, validateAdminPassword } from "./passwordPolicy";

it("requires at least 10 characters for admin passwords", () => {
  expect(validateAdminPassword("Abcdef123").valid).toBe(false);
  expect(validateAdminPassword("Abcdef1234").valid).toBe(true);
  expect(validateAdminPassword("abcdefghijk").errors).toContain("Pelo menos 1 número");
});

it("validates the change password form", () => {
  expect(changePasswordFormError("", "Abcdef1234", "Abcdef1234")).toMatch(/senha atual/);
  expect(changePasswordFormError("old", "short", "short")).toMatch(/10 caracteres/);
  expect(changePasswordFormError("old", "Abcdef1234", "Abcdef12345")).toMatch(/confirmação/);
  expect(changePasswordFormError("Abcdef1234", "Abcdef1234", "Abcdef1234")).toMatch(/diferente/);
  expect(changePasswordFormError("old", "Abcdef1234", "Abcdef1234")).toBeNull();
});
