import {
  parseJsonSafely,
  TICKET_STATUSES,
  isValidTicketStatus,
  isValidNewProviderId,
  logger,
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

describe("logger", () => {
  it("chama console.error para severity ERROR", () => {
    const spy = jest.spyOn(console, "error").mockImplementation(() => {});
    logger.error("falha crítica", { functionName: "test" });
    expect(spy).toHaveBeenCalledTimes(1);
    const logged = JSON.parse(spy.mock.calls[0][0]);
    expect(logged.severity).toBe("ERROR");
    expect(logged.message).toBe("falha crítica");
    expect(logged.functionName).toBe("test");
    spy.mockRestore();
  });

  it("chama console.log para severity INFO", () => {
    const spy = jest.spyOn(console, "log").mockImplementation(() => {});
    logger.info("operação concluída");
    expect(spy).toHaveBeenCalledTimes(1);
    const logged = JSON.parse(spy.mock.calls[0][0]);
    expect(logged.severity).toBe("INFO");
    spy.mockRestore();
  });
});
