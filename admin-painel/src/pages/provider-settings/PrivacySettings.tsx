import { ExternalLink } from "lucide-react";
import { useSettings } from "@/contexts/SettingsContext";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { SettingsPage, SettingsSection } from "@/components/settings/SettingsPage";
import { resolvePublicApiBaseUrl } from "@/shared/config/publicApi";

export function generatedPrivacyUrls(apiBase: string, providerId: string) {
  const base = `${apiBase}/public/providers/${encodeURIComponent(providerId)}`;
  return { privacy: `${base}/privacidade`, deletion: `${base}/exclusao-de-dados` };
}

export default function PrivacySettings() {
  const { config, setConfig, providerId } = useSettings();
  const apiBase = typeof window === "undefined" ? "" : resolvePublicApiBaseUrl(import.meta.env.VITE_API_URL, window.location);
  const generated = providerId ? generatedPrivacyUrls(apiBase, providerId) : null;
  const customUrl = (config.other?.privacyPolicyUrl || "").trim();

  return <SettingsPage title="Privacidade" description="Política de privacidade e exclusão de dados mostradas no aplicativo.">
    <SettingsSection title="Política de privacidade" description="Deixe em branco para usar a página gerada pela plataforma com os dados da sua empresa.">
      <Label htmlFor="privacyPolicyUrl">Link próprio da política (opcional)</Label>
      <Input id="privacyPolicyUrl" type="url" placeholder="https://seuprovedor.com/privacidade" value={config.other?.privacyPolicyUrl || ""}
        onChange={event => setConfig(previous => ({ ...previous, other: { ...previous.other, privacyPolicyUrl: event.target.value } }))} />
      {customUrl && !/^https:\/\//i.test(customUrl) && (
        <p role="alert" className="mt-1.5 text-[12px] text-destructive">Use um link que comece com https://.</p>
      )}
    </SettingsSection>
    {generated && (
      <SettingsSection title="Páginas geradas pela plataforma" description="Usam o nome e os contatos cadastrados em Minha empresa. Também servem para a Google Play.">
        <ul className="grid gap-2 text-[13px]">
          <li>
            <a className="inline-flex items-center gap-1.5 text-primary hover:underline" href={generated.privacy} target="_blank" rel="noopener noreferrer">
              Política de privacidade<ExternalLink className="h-3.5 w-3.5" aria-hidden="true" />
            </a>
            {customUrl && <span className="ml-2 text-[12px] text-muted-foreground">(o app usa o seu link próprio)</span>}
          </li>
          <li>
            <a className="inline-flex items-center gap-1.5 text-primary hover:underline" href={generated.deletion} target="_blank" rel="noopener noreferrer">
              Exclusão de dados<ExternalLink className="h-3.5 w-3.5" aria-hidden="true" />
            </a>
          </li>
        </ul>
      </SettingsSection>
    )}
  </SettingsPage>;
}
