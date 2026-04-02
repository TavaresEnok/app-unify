import {
  parseJsonSafely,
  TICKET_STATUSES,
  isValidTicketStatus,
  isValidNewProviderId,
} from "./utils";

describe("parseJsonSafely", () => {
  it("retorna objeto para JSON válido", () => {
    expect(parseJsonSafely('{"a":1}')).toEqual({ a: 1 });
  });
  it("retorna null para string vazia", () => {
    expect(parseJsonSafely("")).toBeNull();
  });
  it("retorna null para JSON inválido", () => {
    expect(parseJsonSafely("{")).toBeNull();
  });
});

describe("TICKET_STATUSES", () => {
  it("contém os três estados esperados", () => {
    expect(TICKET_STATUSES.size).toBe(3);
    expect(isValidTicketStatus("Aberto")).toBe(true);
    expect(isValidTicketStatus("Invalido")).toBe(false);
  });
});

describe("isValidNewProviderId", () => {
  it("aceita ids válidos", () => {
    expect(isValidNewProviderId("provedor_x")).toBe(true);
    expect(isValidNewProviderId("abc123")).toBe(true);
  });
  it("rejeita maiúsculas e espaços", () => {
    expect(isValidNewProviderId("Provedor")).toBe(false);
    expect(isValidNewProviderId("a b")).toBe(false);
  });
});
