import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { Download, Smartphone } from "lucide-react";
import { useSettings } from "@/contexts/SettingsContext";
import { useAuth } from "@/contexts/AuthContext";
import { applicationDownloadPath, checkPublishedApp, externalHttpsUrl } from "@/shared/api/publishedApp";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";

export default function ApplicationPage() {
  const { provider, providerId, config } = useSettings();
  const { userRole } = useAuth();
  const download = provider ? applicationDownloadPath(provider) : null;
  const [state, setState] = useState<"loading" | "available" | "missing" | "error">("loading");
  const [retry, setRetry] = useState(0);
  const android = externalHttpsUrl(config.appVersion?.storeUrls?.android);
  const ios = externalHttpsUrl(config.appVersion?.storeUrls?.ios);
  useEffect(() => {
    const controller = new AbortController();
    let active = true;
    setState("loading");
    if (!download) { setState("missing"); return () => controller.abort(); }
    const timer = window.setTimeout(() => controller.abort(), 15000);
    checkPublishedApp(download, controller.signal).then(available => {
      if (active) setState(available ? "available" : "missing");
    }).catch(() => { if (active) setState("error"); }).finally(() => window.clearTimeout(timer));
    return () => { active = false; controller.abort(); window.clearTimeout(timer); };
  }, [download, retry]);

  return <div className="space-y-5">
    <div className="flex flex-wrap items-center justify-between gap-3">
      <div><h2 className="text-xl font-bold">Aplicativo</h2><p className="mt-1 text-sm text-muted-foreground">Downloads e orientações de instalação de {String(provider?.name || "seu provedor")}.</p></div>
      {userRole === "superAdmin" && <Button asChild><Link to={`/provedores/${providerId}/app-build`}>Gerar aplicativo</Link></Button>}
    </div>
    <div className="grid gap-4 lg:grid-cols-2">
      <Card><CardHeader><CardTitle className="flex items-center gap-2"><Smartphone className="h-4 w-4" />Android</CardTitle></CardHeader><CardContent className="space-y-4">
        {state === "loading" && <p role="status">Verificando download disponível…</p>}
        {state === "missing" && <p>Nenhum APK disponível para download neste momento.</p>}
        {state === "error" && <div><p>Não foi possível verificar a disponibilidade do APK.</p><Button variant="outline" className="mt-2" onClick={() => setRetry(value => value + 1)}>Tentar novamente</Button></div>}
        {state === "available" && download && <><p>O APK está disponível para instalação direta.</p><Button asChild><a href={download} download><Download className="mr-2 h-4 w-4" />Baixar APK</a></Button></>}
        {android && <p><a href={android} target="_blank" rel="noopener noreferrer" className="font-medium text-primary underline">Abrir link Android configurado</a></p>}
        {ios && <p><a href={ios} target="_blank" rel="noopener noreferrer" className="font-medium text-primary underline">Abrir link iOS configurado</a></p>}
      </CardContent></Card>
      <Card><CardHeader><CardTitle>Versões configuradas</CardTitle></CardHeader><CardContent className="space-y-2 text-sm">
        <p>Última versão indicada: <strong>{config.appVersion?.latestVersion || "Não informada"}</strong></p>
        <p>Versão mínima aceita: <strong>{config.appVersion?.minVersion || "Não informada"}</strong></p>
        <p className="text-muted-foreground">Esses valores definem a política de atualização. A versão do APK pode ser conferida nas informações do aplicativo após a instalação.</p>
        <Link className="inline-block font-medium text-primary underline" to={userRole === "superAdmin" ? `/provedores/${providerId}/force-update` : "/provedor/personalizacao/force-update"}>Configurar atualização</Link>
      </CardContent></Card>
    </div>
    <Card><CardHeader><CardTitle>Como instalar o APK</CardTitle></CardHeader><CardContent>
      <ol className="list-decimal space-y-2 pl-5 text-sm"><li>Abra esta página no celular Android e baixe o APK.</li><li>Abra o arquivo baixado. Se solicitado, permita a instalação de aplicativos para o navegador utilizado.</li><li>Conclua a instalação e abra o aplicativo do provedor.</li><li>Entre com o CPF/CNPJ e a senha da central do assinante.</li></ol>
    </CardContent></Card>
  </div>;
}
