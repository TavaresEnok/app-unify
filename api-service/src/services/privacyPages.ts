// Páginas públicas de privacidade e exclusão de dados (exigidas pela Play
// Store e pela LGPD), geradas a partir da configuração do provedor.

type Data = Record<string, unknown>;

export function publicApiBaseUrl(): string {
  const raw = (process.env.PUBLIC_API_BASE_URL || "https://appisp.com.br/api").trim().replace(/\/+$/, "");
  return /^https:\/\/[^\s/]+(?:\/[^\s]*)?$/i.test(raw) ? raw : "https://appisp.com.br/api";
}

export function defaultPrivacyUrls(providerId: string): { privacyPolicyUrl: string; dataDeletionUrl: string } {
  const base = `${publicApiBaseUrl()}/public/providers/${encodeURIComponent(providerId)}`;
  return { privacyPolicyUrl: `${base}/privacidade`, dataDeletionUrl: `${base}/exclusao-de-dados` };
}

function text(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function escapeHtml(value: string): string {
  return value.replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c] as string));
}

function object(value: unknown): Data {
  return value && typeof value === "object" && !Array.isArray(value) ? value as Data : {};
}

interface Contact { label: string; value: string; href?: string }

// Contatos públicos já configurados no app (canais de suporte e dados da empresa).
export function providerContacts(data: Data): Contact[] {
  const details = object(data.details);
  const contacts: Contact[] = [];
  const seen = new Set<string>();
  const add = (label: string, value: string, href?: string) => {
    const key = `${label}:${value}`.toLowerCase();
    if (!value || seen.has(key) || contacts.length >= 8) return;
    seen.add(key);
    contacts.push({ label, value, href });
  };
  const email = text(details.email);
  if (email && /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) add("E-mail", email, `mailto:${email}`);
  const phone = text(details.phone) || text(details.telefone);
  if (phone) add("Telefone", phone, `tel:${phone.replace(/[^\d+]/g, "")}`);
  const channels = [
    ...(Array.isArray(data.supportChannels) ? data.supportChannels : []),
    ...(Array.isArray(data.supportContacts) ? data.supportContacts : []),
  ].map(object);
  for (const channel of channels) {
    const type = text(channel.type).toLowerCase();
    const value = text(channel.value) || text(channel.phone) || text(channel.email) || text(channel.url);
    if (!value) continue;
    if (type.includes("whats")) add("WhatsApp", value, `https://wa.me/${value.replace(/\D/g, "")}`);
    else if (type.includes("mail") || /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)) add("E-mail", value, `mailto:${value}`);
    else if (type.includes("phone") || type.includes("tel") || /^[\d\s()+-]{8,}$/.test(value)) add("Telefone", value, `tel:${value.replace(/[^\d+]/g, "")}`);
    else if (/^https:\/\//i.test(value)) add(text(channel.name) || "Site", value, value);
  }
  const site = text(details.website);
  if (/^https:\/\//i.test(site)) add("Site", site, site);
  return contacts;
}

function providerName(data: Data, fallback: string): string {
  const details = object(data.details);
  return text(details.nomeFantasia) || text(details.commercialName) || text(data.name) || fallback;
}

function legalName(data: Data): string {
  const details = object(data.details);
  const razao = text(details.razaoSocial);
  const cnpj = text(details.cnpj);
  return [razao, cnpj ? `CNPJ ${cnpj}` : ""].filter(Boolean).join(" · ");
}

function contactsHtml(contacts: Contact[]): string {
  if (!contacts.length) return "<p>Use os canais de atendimento informados no aplicativo, na tela <strong>Suporte</strong>.</p>";
  return `<ul class="contacts">${contacts.map((c) => {
    const value = escapeHtml(c.value);
    const link = c.href && /^(https:|mailto:|tel:)/i.test(c.href) ? `<a href="${escapeHtml(c.href)}" rel="noopener">${value}</a>` : value;
    return `<li><span>${escapeHtml(c.label)}</span> ${link}</li>`;
  }).join("")}</ul>`;
}

function layout(title: string, name: string, color: string, body: string): string {
  const accent = /^#[0-9a-f]{3,8}$/i.test(color) ? color : "#1f6feb";
  return `<!doctype html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${escapeHtml(title)} · ${escapeHtml(name)}</title>
<meta name="robots" content="index,follow">
<style>
:root { color-scheme: light dark; --accent: ${accent}; --text: #1d2330; --muted: #5b6475; --bg: #ffffff; --card: #f5f7fa; }
@media (prefers-color-scheme: dark) { :root { --text: #e8ecf3; --muted: #a7b0c0; --bg: #11151c; --card: #1a2029; } }
* { box-sizing: border-box; }
body { margin: 0; background: var(--bg); color: var(--text); font: 16px/1.6 system-ui, -apple-system, "Segoe UI", Roboto, sans-serif; }
main { max-width: 760px; margin: 0 auto; padding: 32px 16px 64px; }
header { border-bottom: 3px solid var(--accent); padding-bottom: 12px; margin-bottom: 24px; }
h1 { font-size: 1.6rem; margin: 0 0 4px; }
h2 { font-size: 1.15rem; margin: 28px 0 8px; }
p, li { color: var(--text); }
.muted { color: var(--muted); font-size: .9rem; }
.contacts { list-style: none; padding: 0; }
.contacts li { background: var(--card); border-radius: 10px; padding: 10px 14px; margin: 8px 0; }
.contacts span { display: inline-block; min-width: 92px; color: var(--muted); }
a { color: var(--accent); }
</style>
</head>
<body><main>${body}</main></body>
</html>`;
}

export function privacyPolicyHtml(providerId: string, data: Data, updatedAt: string): string {
  const name = providerName(data, providerId);
  const legal = legalName(data);
  const urls = defaultPrivacyUrls(providerId);
  const body = `
<header>
  <h1>Política de privacidade</h1>
  <p class="muted">Aplicativo ${escapeHtml(name)}${legal ? ` · ${escapeHtml(legal)}` : ""}</p>
</header>
<p>Esta política explica quais dados o aplicativo de assinante da <strong>${escapeHtml(name)}</strong> usa, para quê e como você pode pedir a exclusão. O tratamento segue a Lei Geral de Proteção de Dados (Lei 13.709/2018).</p>

<h2>Quem cuida dos seus dados</h2>
<p>A <strong>${escapeHtml(name)}</strong> é a controladora dos dados do seu contrato de internet. O aplicativo é operado por um parceiro de tecnologia que trata os dados apenas para prestar este serviço ao provedor.</p>

<h2>Dados que usamos</h2>
<ul>
  <li><strong>CPF ou CNPJ</strong>: para entrar no app e localizar o seu contrato no sistema do provedor. Não pedimos senha.</li>
  <li><strong>Dados do contrato e faturas</strong>: nome, plano, situação do contrato, valores, vencimentos, boleto e código PIX, consultados no sistema do provedor para mostrar no app.</li>
  <li><strong>Consumo e diagnóstico</strong>: uso de internet, sinal da fibra, estado do roteador, aparelhos conectados e resultados de testes de velocidade e de conexão que você fizer no app.</li>
  <li><strong>Notificações</strong>: um identificador do aparelho (token de notificação) para enviar avisos de fatura e comunicados do provedor.</li>
  <li><strong>Localização</strong>: o Android só mostra o nome da rede Wi-Fi conectada quando o app tem permissão de localização. Usamos essa permissão apenas para ler o nome da rede no diagnóstico. Não registramos nem guardamos sua localização.</li>
  <li><strong>Chamados e anexos</strong>: mensagens e fotos que você enviar ao suporte pelo app.</li>
</ul>

<h2>Para que usamos</h2>
<p>Para mostrar suas faturas e seu contrato, ajudar a resolver problemas na conexão, permitir alterar o nome e a senha do Wi-Fi quando o roteador é gerenciado pelo provedor, enviar avisos e prestar atendimento. Não vendemos seus dados e não os usamos para publicidade de terceiros.</p>

<h2>Com quem compartilhamos</h2>
<p>Com o sistema de gestão do provedor (onde o contrato já existe) e com serviços necessários ao funcionamento do app, como o envio de notificações (Firebase Cloud Messaging, do Google). Os dados ficam em servidores do parceiro de tecnologia, com acesso restrito e protegido.</p>

<h2>Por quanto tempo guardamos</h2>
<ul>
  <li>Sessão do app: até 30 dias sem uso, ou até você sair da conta.</li>
  <li>Token de notificação: até você sair da conta ou ficar 120 dias sem usar o app.</li>
  <li>Resultados de diagnóstico e chamados: pelo tempo necessário ao atendimento e às obrigações legais do provedor.</li>
  <li>Dados do contrato e das faturas continuam no sistema do provedor conforme as regras de cobrança e a legislação.</li>
</ul>

<h2>Seus direitos</h2>
<p>Você pode pedir acesso, correção ou exclusão dos seus dados, saber com quem foram compartilhados e revogar consentimentos. Veja como pedir a exclusão em <a href="${escapeHtml(urls.dataDeletionUrl)}">Exclusão de dados</a>.</p>

<h2>Fale com a ${escapeHtml(name)}</h2>
${contactsHtml(providerContacts(data))}

<p class="muted">Atualizada em ${escapeHtml(updatedAt)}.</p>`;
  return layout("Política de privacidade", name, text(data.themeColor), body);
}

export function dataDeletionHtml(providerId: string, data: Data, updatedAt: string): string {
  const name = providerName(data, providerId);
  const urls = defaultPrivacyUrls(providerId);
  const body = `
<header>
  <h1>Exclusão de dados</h1>
  <p class="muted">Aplicativo ${escapeHtml(name)}</p>
</header>
<p>Você pode pedir a exclusão dos dados ligados ao aplicativo da <strong>${escapeHtml(name)}</strong> a qualquer momento.</p>

<h2>Como pedir</h2>
<ol>
  <li>Entre em contato com a ${escapeHtml(name)} por um dos canais abaixo.</li>
  <li>Informe que deseja excluir os dados do aplicativo e o CPF ou CNPJ do titular do contrato.</li>
  <li>Para sua segurança, o provedor pode confirmar a sua identidade antes de concluir.</li>
</ol>
${contactsHtml(providerContacts(data))}

<h2>O que é excluído</h2>
<ul>
  <li>Cadastro de acesso ao app e sessões abertas.</li>
  <li>Tokens de notificação dos seus aparelhos.</li>
  <li>Resultados de diagnóstico e testes feitos pelo app.</li>
  <li>Chamados e anexos enviados pelo app, quando não forem necessários a obrigações legais.</li>
</ul>

<h2>O que pode ser mantido</h2>
<p>Dados do contrato, faturas e pagamentos ficam no sistema do provedor pelo prazo exigido por lei (por exemplo, obrigações fiscais e da Anatel). Eles não são apagados pelo app.</p>

<p>O pedido é atendido em até 15 dias. Para sair só deste aparelho, use <strong>Sair</strong> no app: a sessão e o token de notificação do aparelho são removidos na hora.</p>

<p>Leia também a <a href="${escapeHtml(urls.privacyPolicyUrl)}">Política de privacidade</a>.</p>
<p class="muted">Atualizada em ${escapeHtml(updatedAt)}.</p>`;
  return layout("Exclusão de dados", name, text(data.themeColor), body);
}

// Campos extras que o app lê na config pública: links de privacidade (gerados
// quando o provedor não tem um próprio) e a política de atualização.
export function publicConfigExtras(providerId: string, data: Data): Data {
  const other = object(data.other);
  const legacyOther = object(object(data.config).other);
  const custom = text(other.privacyPolicyUrl) || text(legacyOther.privacyPolicyUrl);
  const defaults = defaultPrivacyUrls(providerId);
  const extras: Data = {
    privacyPolicyUrl: /^https:\/\//i.test(custom) ? custom : defaults.privacyPolicyUrl,
    dataDeletionUrl: defaults.dataDeletionUrl,
  };
  const version = object(data.appVersion);
  if (Object.keys(version).length) {
    const storeUrls = object(version.storeUrls);
    const packageName = text(data.applicationId) || text(data.packageName);
    const storeUrl = [text(version.storeUrl), text(storeUrls.android)].find((u) => /^https:\/\//i.test(u))
      || (/^[a-z][a-z0-9_]*(\.[a-z0-9_]+)+$/i.test(packageName) ? `https://play.google.com/store/apps/details?id=${packageName}` : "");
    const minVersion = version.forceUpdate === false ? "" : text(version.minVersion);
    const latestVersion = text(version.latestVersion);
    const normalized: Data = { ...version };
    if (minVersion) normalized.minVersion = minVersion; else delete normalized.minVersion;
    if (latestVersion) normalized.latestVersion = latestVersion; else delete normalized.latestVersion;
    if (storeUrl) normalized.storeUrl = storeUrl;
    if (normalized.minVersion || normalized.latestVersion) extras.appVersion = normalized;
  }
  return extras;
}
