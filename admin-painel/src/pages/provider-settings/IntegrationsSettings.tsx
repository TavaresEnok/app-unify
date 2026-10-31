import { useState } from "react";
import { useAuth } from "@/contexts/AuthContext";
import { useSettings } from "@/contexts/SettingsContext";
import { auth } from "@/firebase/config";
import { resolvePublicApiBaseUrl } from "@/shared/config/publicApi";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { toast } from "sonner";

export default function IntegrationsSettings() {
  const { userRole } = useAuth();
  const { providerId } = useSettings();
  const [apiToken, setToken] = useState("");
  const [sgpBaseUrl, setUrl] = useState("");
  const [appName, setApp] = useState("");
  const [saving, setSaving] = useState(false);
  if (userRole !== "superAdmin") return <p>Integração administrada pela equipe SaaS.</p>;
  const replace = async () => {
    setSaving(true);
    try {
      if (!auth.currentUser) throw new Error("Sessão necessária.");
      const base = resolvePublicApiBaseUrl(import.meta.env.VITE_API_URL, window.location);
      const response = await fetch(`${base}/admin/providers/${encodeURIComponent(providerId)}/integration`, {
        method: "POST", headers: { "Content-Type": "application/json", Authorization: `Bearer ${await auth.currentUser.getIdToken(true)}` },
        body: JSON.stringify({ apiToken, sgpBaseUrl, appName }),
      });
      if (!response.ok) throw new Error("Não foi possível substituir a integração.");
      setToken(""); setUrl(""); setApp("");
      toast.success("Integração substituída.");
    } catch (error) { toast.error(error instanceof Error ? error.message : "Falha ao substituir."); }
    finally { setSaving(false); }
  };
  return <section className="space-y-4">
    <h1>Substituir integração SGP</h1>
    <p>Informe todos os novos valores. O token armazenado não é exibido.</p>
    <Label htmlFor="replacement-token">Novo token</Label>
    <Input id="replacement-token" type="password" autoComplete="off" value={apiToken} onChange={e => setToken(e.target.value)} />
    <Label htmlFor="replacement-url">URL SGP</Label>
    <Input id="replacement-url" value={sgpBaseUrl} onChange={e => setUrl(e.target.value)} />
    <Label htmlFor="replacement-app">App de integração</Label>
    <Input id="replacement-app" value={appName} onChange={e => setApp(e.target.value)} />
    <Button disabled={saving || !apiToken || !sgpBaseUrl || !appName} onClick={replace}>Substituir integração</Button>
  </section>;
}
