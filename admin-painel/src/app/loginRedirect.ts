/** Aceita só caminhos internos do painel (evita redirecionamento aberto). */
export function safeNextPath(raw: string | null | undefined): string | null {
  if (!raw) return null;
  const value = raw.trim();
  if (!value.startsWith("/") || value.startsWith("//") || value.startsWith("/\\")) return null;
  if (/^\/login(?:[/?#]|$)/.test(value)) return null;
  if ([...value].some((char) => char.charCodeAt(0) < 0x20)) return null;
  return value;
}

export function loginPathWithNext(pathname: string, search = ""): string {
  const next = safeNextPath(`${pathname}${search}`);
  return next ? `/login?next=${encodeURIComponent(next)}` : "/login";
}

export function canOpenAfterLogin(path: string, role: "superAdmin" | "providerAdmin"): boolean {
  // Um admin de provedor não deve cair em rotas de Super Admin (e vice-versa evita telas vazias).
  if (role === "providerAdmin") return path.startsWith("/provedor/") || path === "/provedor" || path === "/conta/senha";
  return !path.startsWith("/provedor/");
}
