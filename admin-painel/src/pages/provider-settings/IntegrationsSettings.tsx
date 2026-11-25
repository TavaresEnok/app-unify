import { useEffect, useState } from "react";
import { useAuth } from "@/contexts/AuthContext";
import { useSettings } from "@/contexts/SettingsContext";
import { auth } from "@/firebase/config";
import { resolvePublicApiBaseUrl } from "@/shared/config/publicApi";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { toast } from "sonner";
import {
  fetchAcsConfig,
  saveAcsConfig,
  testAcsConnection,
  type AcsDriverType,
  type AcsFeatureFlags,
} from "@/shared/api/tr069";

const DEFAULT_FEATURES: AcsFeatureFlags = {
  wifi: true,
  reboot: true,
  hosts: true,
  guestWifi: true,
  channelOptimize: true,
  speedDiagnostic: true,
};

export default function IntegrationsSettings() {
  const { userRole } = useAuth();
  const { providerId } = useSettings();
  const [apiToken, setToken] = useState("");
  const [sgpBaseUrl, setUrl] = useState("");
  const [appName, setApp] = useState("");
  const [erp, setErp] = useState<"sgp" | "ixc">("sgp");
  const [saving, setSaving] = useState(false);

  // TR-069 / ACS state
  const [acsDriver, setAcsDriver] = useState<AcsDriverType>("none");
  const [acsEnabled, setAcsEnabled] = useState(false);
  const [acsUrl, setAcsUrl] = useState("");
  const [acsUsername, setAcsUsername] = useState("");
  const [acsPassword, setAcsPassword] = useState("");
  const [acsApiKey, setAcsApiKey] = useState("");
  const [hasSavedCreds, setHasSavedCreds] = useState(false);
  const [acsFeatures, setAcsFeatures] = useState<AcsFeatureFlags>(DEFAULT_FEATURES);
  const [savingAcs, setSavingAcs] = useState(false);
  const [testingAcs, setTestingAcs] = useState(false);

  useEffect(() => {
    if (userRole !== "superAdmin" || !providerId || !auth?.currentUser) return;
    let alive = true;
    fetchAcsConfig(providerId)
      .then((cfg) => {
        if (!alive) return;
        setAcsDriver(cfg.driver);
        setAcsEnabled(cfg.enabled);
        setAcsUrl(cfg.url);
        setAcsUsername(cfg.username);
        setHasSavedCreds(cfg.hasPassword || cfg.hasApiKey);
        setAcsFeatures(cfg.features);
      })
      .catch(() => { /* silencioso se ainda não configurado */ });
    return () => { alive = false; };
  }, [userRole, providerId]);

  if (userRole !== "superAdmin") return <p>Integração administrada pela equipe SaaS.</p>;

  const replace = async () => {
    setSaving(true);
    try {
      if (!auth.currentUser) throw new Error("Sessão necessária.");
      const base = resolvePublicApiBaseUrl(import.meta.env.VITE_API_URL, window.location);
      const response = await fetch(`${base}/admin/providers/${encodeURIComponent(providerId)}/integration`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${await auth.currentUser.getIdToken(true)}`,
        },
        body: JSON.stringify(erp === "ixc" ? { erp, apiToken, sgpBaseUrl } : { erp, apiToken, sgpBaseUrl, appName }),
      });
      if (!response.ok) throw new Error("Não foi possível substituir a integração.");
      const data = await response.json().catch(() => ({}));
      setToken(""); setUrl(""); setApp(""); setErp("sgp");
      toast.success(
        data?.syncQueued
          ? "Integração salva e sincronização inicial de clientes iniciada."
          : "Integração substituída.",
      );
    } catch (error) {
      toast.error(error instanceof Error ? error.message : "Falha ao substituir.");
    } finally {
      setSaving(false);
    }
  };

  const handleSaveAcs = async () => {
    setSavingAcs(true);
    try {
      const res = await saveAcsConfig(providerId, {
        driver: acsDriver,
        enabled: acsDriver !== "none" && acsEnabled,
        url: acsUrl,
        username: acsUsername,
        password: acsPassword || undefined,
        apiKey: acsApiKey || undefined,
        features: acsFeatures,
      });
      setAcsPassword("");
      setAcsApiKey("");
      setHasSavedCreds(res.data.hasPassword || res.data.hasApiKey);
      toast.success(res.message);
    } catch (error) {
      toast.error(error instanceof Error ? error.message : "Não foi possível salvar TR-069/ACS.");
    } finally {
      setSavingAcs(false);
    }
  };

  const handleTestAcs = async () => {
    setTestingAcs(true);
    try {
      const res = await testAcsConnection(providerId);
      toast.success(res.data.message);
    } catch (error) {
      toast.error(error instanceof Error ? error.message : "Falha ao testar conexão ACS.");
    } finally {
      setTestingAcs(false);
    }
  };

  const toggleFeature = (key: keyof AcsFeatureFlags) => {
    setAcsFeatures((prev) => ({ ...prev, [key]: !prev[key] }));
  };

  return (
    <div className="space-y-8">
      <section className="space-y-4">
        <h1>Substituir integração do ERP</h1>
        <p>Informe todos os novos valores. O token armazenado não é exibido.</p>
        <Label htmlFor="replacement-erp">Sistema (ERP)</Label>
        <Select value={erp} onValueChange={(value) => setErp(value === "ixc" ? "ixc" : "sgp")}>
          <SelectTrigger id="replacement-erp"><SelectValue /></SelectTrigger>
          <SelectContent>
            <SelectItem value="sgp">SGP</SelectItem>
            <SelectItem value="ixc">IXC Provedor</SelectItem>
          </SelectContent>
        </Select>
        <Label htmlFor="replacement-token">{erp === "ixc" ? "Token do usuário de API (IXC)" : "Novo token"}</Label>
        <Input id="replacement-token" type="password" autoComplete="off" value={apiToken} onChange={e => setToken(e.target.value)} />
        <Label htmlFor="replacement-url">{erp === "ixc" ? "URL do IXC (sem /webservice/v1)" : "URL SGP"}</Label>
        <Input id="replacement-url" value={sgpBaseUrl} onChange={e => setUrl(e.target.value)} />
        {erp === "sgp" && (
          <>
            <Label htmlFor="replacement-app">App de integração</Label>
            <Input id="replacement-app" value={appName} onChange={e => setApp(e.target.value)} />
          </>
        )}
        <Button disabled={saving || !apiToken || !sgpBaseUrl || (erp === "sgp" && !appName)} onClick={replace}>Substituir integração</Button>
      </section>

      <section className="space-y-4 border-t border-[#EEF0F4] pt-6">
        <div className="flex items-center justify-between gap-4">
          <div>
            <h2 className="text-lg font-semibold text-[#1A2233]">TR-069 / ACS (Gestão Remota de Roteadores)</h2>
            <p className="text-[13px] text-[#687181]">
              Conecte o SGP CPE Manager, GenieACS ou Anlix Flashman para liberar Wi-Fi, Reboot, Hosts, Otimização de Canal e Diagnóstico TR-143.
            </p>
          </div>
          <Switch
            checked={acsEnabled && acsDriver !== "none"}
            disabled={acsDriver === "none" || savingAcs}
            onCheckedChange={setAcsEnabled}
          />
        </div>

        <div className="grid gap-3 sm:grid-cols-2">
          <div className="grid gap-1.5">
            <Label>Servidor / Driver TR-069</Label>
            <Select
              value={acsDriver}
              onValueChange={(v) => {
                const next = v as AcsDriverType;
                setAcsDriver(next);
                setAcsEnabled(next !== "none");
              }}
            >
              <SelectTrigger><SelectValue /></SelectTrigger>
              <SelectContent>
                <SelectItem value="none">Desativado</SelectItem>
                <SelectItem value="sgp">SGP CPE Manager (usa credenciais SGP)</SelectItem>
                <SelectItem value="genieacs">GenieACS (NBI REST — TR-098 e TR-181)</SelectItem>
                <SelectItem value="flashman">Anlix Flashman (API v2)</SelectItem>
              </SelectContent>
            </Select>
          </div>

          {(acsDriver === "genieacs" || acsDriver === "flashman") && (
            <div className="grid gap-1.5">
              <Label htmlFor="acs-url">URL do servidor ACS</Label>
              <Input
                id="acs-url"
                placeholder={acsDriver === "genieacs" ? "https://acs.provedor.com.br:7557" : "https://flashman.provedor.com.br"}
                value={acsUrl}
                onChange={(e) => setAcsUrl(e.target.value)}
              />
            </div>
          )}
        </div>

        {(acsDriver === "genieacs" || acsDriver === "flashman") && (
          <div className="grid gap-3 sm:grid-cols-3">
            <div className="grid gap-1.5">
              <Label htmlFor="acs-user">Usuário (Basic Auth)</Label>
              <Input id="acs-user" autoComplete="off" value={acsUsername} onChange={(e) => setAcsUsername(e.target.value)} />
            </div>
            <div className="grid gap-1.5">
              <Label htmlFor="acs-pass">Senha {hasSavedCreds ? "(salva)" : ""}</Label>
              <Input
                id="acs-pass"
                type="password"
                autoComplete="off"
                placeholder={hasSavedCreds ? "Vazio mantém a atual" : "Senha do ACS"}
                value={acsPassword}
                onChange={(e) => setAcsPassword(e.target.value)}
              />
            </div>
            <div className="grid gap-1.5">
              <Label htmlFor="acs-key">API Key / Bearer Token (opcional)</Label>
              <Input
                id="acs-key"
                type="password"
                autoComplete="off"
                placeholder={hasSavedCreds ? "Vazio mantém o atual" : "Token da API"}
                value={acsApiKey}
                onChange={(e) => setAcsApiKey(e.target.value)}
              />
            </div>
          </div>
        )}

        {acsDriver !== "none" && (
          <div className="space-y-2 rounded-lg border border-[#EEF0F4] bg-[#F8FAFC] p-3.5">
            <div className="text-[12.5px] font-semibold text-[#1A2233]">Recursos liberados para o assinante no aplicativo</div>
            <div className="grid gap-2 sm:grid-cols-2 lg:grid-cols-3">
              {([
                { key: "wifi", label: "Editar Wi-Fi e QR Code" },
                { key: "reboot", label: "Reiniciar roteador (Reboot)" },
                { key: "hosts", label: "Ver dispositivos conectados" },
                { key: "guestWifi", label: "Rede para visitantes (Guest)" },
                { key: "channelOptimize", label: "Otimizar canal Wi-Fi" },
                { key: "speedDiagnostic", label: "Diagnóstico no roteador (TR-143)" },
              ] as const).map((item) => (
                <label key={item.key} className="flex items-center justify-between gap-2 rounded-md border border-[#E4E7EC] bg-white px-3 py-2 text-[12.5px]">
                  <span>{item.label}</span>
                  <Switch checked={acsFeatures[item.key]} onCheckedChange={() => toggleFeature(item.key)} />
                </label>
              ))}
            </div>
          </div>
        )}

        <div className="flex flex-wrap gap-2">
          <Button onClick={() => void handleSaveAcs()} disabled={savingAcs}>
            {savingAcs ? "Salvando…" : "Salvar configuração TR-069"}
          </Button>
          {acsDriver !== "none" && acsEnabled && (
            <Button variant="outline" onClick={() => void handleTestAcs()} disabled={testingAcs}>
              {testingAcs ? "Testando…" : "Testar conexão ACS"}
            </Button>
          )}
        </div>
      </section>
    </div>
  );
}
