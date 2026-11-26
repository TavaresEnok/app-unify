import { useEffect, useState } from 'react';
import { clearBuildResult, currentBuildState, isBuildTracked, subscribeBuild, trackBuild, type BuildState } from '@/features/app-build/buildTracker';
import { useSettings } from '@/contexts/SettingsContext';
import { useAuth } from '@/contexts/AuthContext';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import { Loader2, Smartphone, Download, AlertTriangle, CheckCircle, Save } from 'lucide-react';
import { toast } from 'sonner';
import { SettingsPage, SettingsSection } from '@/components/settings/SettingsPage';
import { publicDownloadUrl, runtimeConfig } from '@/shared/config/runtime';
import { resolvePublicApiBaseUrl } from '@/shared/config/publicApi';
import { getErrorMessage } from '@/shared/errors';
import BuildConfirmationDialog from '@/components/BuildConfirmationDialog';
import { confirmBuildSession, needsBuildConfirmation } from '@/shared/settings/buildSession';

interface BuildResult {
    success: boolean;
    jobId?: string;
    status?: 'preparing' | 'running' | 'succeeded' | 'failed';
    format?: 'apk' | 'aab';
    error?: string;
    downloadUrl?: string;
    versionName?: string;
    versionCode?: string | number;
}

interface UploadResult {
    success: boolean;
    url?: string;
    error?: string;
}

async function parseBuildResponse(response: Response): Promise<BuildResult> {
    const body = await response.text();

    if (!body) {
        return { success: response.ok };
    }

    try {
        return JSON.parse(body) as BuildResult;
    } catch {
        const readableBody = body
            .replace(/<[^>]*>/g, ' ')
            .replace(/\s+/g, ' ')
            .trim()
            .slice(0, 240);

        throw new Error(readableBody ? `HTTP ${response.status}: ${readableBody}` : `HTTP ${response.status}`);
    }
}

async function fetchBuildJob(jobId: string, token: string) {
    const response = await fetch(
        `${runtimeConfig.apkBuilderBaseUrl}/jobs/${encodeURIComponent(jobId)}`,
        { headers: { 'Authorization': `Bearer ${token}` } },
    );
    const body = await parseBuildResponse(response);
    return { ok: response.ok, status: response.status, body };
}

type BuildUser = { getIdToken: () => Promise<string> };

// Segue o build fora do ciclo de vida da página: o toast final aparece em
// qualquer tela do painel, e o resultado fica salvo para quando o admin voltar.
function followBuild(providerId: string, jobId: string, format: 'apk' | 'aab', user: BuildUser, startedAt?: number) {
    if (isBuildTracked(providerId)) return;
    trackBuild(providerId, jobId, format, () => user.getIdToken(), fetchBuildJob, { startedAt })
        .then((result) => {
            if (result.success) {
                toast.success(`${format.toUpperCase()} gerado com sucesso!`, {
                    description: 'O link de download está na tela Gerar app.',
                    duration: 15_000,
                });
            } else {
                toast.error(`Erro ao gerar ${format.toUpperCase()}`, { description: result.error });
            }
        })
        .catch(() => {
            toast.warning('Sem conexão com o gerador', {
                description: 'A geração continua no servidor. Volte à tela Gerar app para acompanhar.',
            });
        });
}

// FINAL-FINAL FIX - RENAMED FILE
export default function AndroidBuilderPage() {
    const { userRole, user } = useAuth();
    const settings = useSettings();
    const [starting, setStarting] = useState(false);
    const [startError, setStartError] = useState<string | null>(null);
    const [pendingFormat, setPendingFormat] = useState<'apk' | 'aab' | null>(null);
    const trackedProviderId = settings.providerId || settings.provider?.id || '';
    const [buildState, setBuildState] = useState<BuildState>(() =>
        trackedProviderId ? currentBuildState(trackedProviderId) : { kind: 'idle' });

    useEffect(() => {
        if (!trackedProviderId) return;
        setBuildState(currentBuildState(trackedProviderId));
        const unsubscribe = subscribeBuild(trackedProviderId, setBuildState);
        // Retoma um build iniciado antes (outra tela, recarga ou nova aba).
        const state = currentBuildState(trackedProviderId);
        if (state.kind === 'running' && user) {
            followBuild(trackedProviderId, state.jobId, state.format, user, state.startedAt);
        }
        return unsubscribe;
    }, [trackedProviderId, user]);

    const loading = starting || buildState.kind === 'running';
    const lastResult: BuildResult | null = startError
        ? { success: false, error: startError }
        : buildState.kind === 'done' ? (buildState.result as BuildResult) : null;

    // --- SAFETY CHECK (CRITICAL) ---
    // Handle undefined context or missing provider data gracefully
    const providerData = settings.provider;

    if (!providerData) {
        // If settings exists but provider is null, we are Loading or it failed.
        if (settings.loading) {
            return <div className="flex items-center justify-center p-8 text-muted-foreground"><Loader2 className="animate-spin mr-2" /> Carregando dados do provedor...</div>;
        }
        return <div className="p-8 text-destructive">Erro: Dados do provedor não encontrados.</div>;
    }

    // 1. SECURITY CHECK: Only Super Admin can see this page
    if (userRole !== 'superAdmin') {
        return (
            <Card className="border-destructive/50">
                <CardHeader>
                    <CardTitle className="flex items-center gap-2 text-destructive">
                        <AlertTriangle className="h-5 w-5" />
                        Acesso Restrito
                    </CardTitle>
                    <CardDescription>
                        Esta funcionalidade de construção de APK é exclusiva para administração interna.
                        Entre em contato com o suporte se precisar de uma nova versão do seu aplicativo.
                    </CardDescription>
                </CardHeader>
            </Card>
        );
    }

    const handleGenerateApk = async (format: 'apk' | 'aab' = 'apk') => {
        const providerId = settings.providerId || providerData?.id;

        if (!providerId) {
            toast.error("Erro: provedor não identificado.", {
                description: "Não foi possível identificar o ID do provedor."
            });
            return;
        }

        // Validate Requirements
        const appName = providerData.name;
        const logoUrl = settings.config.logoUrl?.trim();

        if (!logoUrl) {
            toast.error("O provedor não tem uma Logo configurada.", {
                description: "Configure a logo na aba 'Aparência' antes de gerar o APK."
            });
            return;
        }

        setStarting(true);
        setStartError(null);
        clearBuildResult(providerId);

        try {
            if (!user) {
                throw new Error("Usuário não autenticado");
            }
            if (await needsBuildConfirmation(user)) {
                setPendingFormat(format);
                return;
            }
            await settings.saveConfig();
            const token = await user.getIdToken();

            const response = await fetch(`${runtimeConfig.apkBuilderBaseUrl}/generate-apk`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify({
                    providerId,
                    appName,
                    logoUrl,
                    format,
                    async: true,
                })
            });

            const result = await parseBuildResponse(response);

            if (!response.ok || !result.success) {
                if (response.status === 403 && result.error === 'build-authorization-denied' && await needsBuildConfirmation(user)) {
                    setPendingFormat(format);
                    return;
                }
                throw new Error(result.error === 'logo-download-failed'
                    ? 'Não foi possível baixar a logo. Verifique se a URL permite acesso público e tente novamente.'
                    : result.error === 'build-authorization-denied'
                        ? 'Esta conta não tem autorização para gerar aplicativos. Verifique o acesso de gerente.'
                        : result.error || `HTTP ${response.status}`);
            }
            if (response.status === 202 && result.jobId) {
                toast.info(`${format.toUpperCase()} em geração`, {
                    description: 'Pode sair desta tela: a geração continua e você será avisado ao terminar.',
                });
                followBuild(providerId, result.jobId, format, user);
                return;
            }

            // Resposta síncrona (builder antigo): já veio pronta.
            toast.success(`${format.toUpperCase()} Gerado com Sucesso!`);
            setStartError(null);
            setBuildState({ kind: 'done', result: { ...result, format } });
        } catch (error) {
            console.error(error);
            toast.error(`Erro ao gerar ${format.toUpperCase()}`, {
                description: getErrorMessage(error)
            });
            setStartError(getErrorMessage(error));
        } finally {
            setStarting(false);
        }
    };



    return (
        <SettingsPage
            title="Gerar app"
            description="Gere versões do aplicativo para teste (APK) ou para loja (AAB)."
            icon={Smartphone}
        >
            {pendingFormat && user && <BuildConfirmationDialog
                email={user.email || ''}
                format={pendingFormat}
                onCancel={() => setPendingFormat(null)}
                onConfirm={async password => {
                    await confirmBuildSession(user, password);
                    const format = pendingFormat;
                    setPendingFormat(null);
                    void handleGenerateApk(format);
                }}
            />}

            {window.location.protocol === 'https:' && runtimeConfig.apkBuilderBaseUrl.startsWith('http:') && (
                <Alert variant="destructive" className="bg-amber-500/10 text-amber-600 border-amber-500/50 dark:text-amber-400">
                    <AlertTriangle className="h-4 w-4" />
                    <AlertTitle>Restrição de Segurança do Navegador</AlertTitle>
                    <AlertDescription>
                        Você está acessando pelo painel em Nuvem (HTTPS).<br />
                        O endereço configurado para o gerador usa HTTP e será bloqueado pelo navegador.<br />
                        <br />
                        <strong>Para gerar o APK, acesse o painel localmente:</strong><br />
                        <a href={runtimeConfig.panelUrl} target="_blank" rel="noreferrer" className="font-mono underline font-bold">
                            {runtimeConfig.panelUrl}
                        </a>
                        <br />
                        <span className="text-xs opacity-75">(Se o painel local estiver desatualizado, lembre-se de rodar "docker-compose build frontend" no servidor)</span>
                    </AlertDescription>
                </Alert>
            )}

            <SettingsSection title="Gerador de Versão Android" description={`Configurações atuais: ${providerData.name} (${providerData.id})`}>
                <div className="space-y-4">
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div className="space-y-2">
                            <label htmlFor="build-app-name" className="text-sm font-medium">Nome do Aplicativo</label>
                            <div className="flex gap-2">
                                <Input
                                    id="build-app-name"
                                    value={providerData.name || ''}
                                    readOnly
                                />
                            </div>
                            <p className="text-xs text-muted-foreground">Nome que aparecerá instalado no celular, definido no cadastro do provedor.</p>
                        </div>

                        <div className="space-y-2">
                            <label htmlFor="build-logo-url" className="text-sm font-medium">Logo do App (Ícone)</label>
                            <div className="flex gap-2">
                                <div className="flex-1">
                                    <Input
                                        id="build-logo-url"
                                        value={settings.config.logoUrl || ''}
                                        onChange={(e) => {
                                            const val = e.target.value;
                                            settings.setConfig((prev) => ({
                                                ...prev,
                                                logoUrl: val
                                            }));
                                        }}
                                        placeholder="URL da Logo ou Upload..."
                                    />
                                </div>
                                <div className="relative">
                                    <Input
                                        type="file"
                                        id="logo-upload"
                                        accept="image/png, image/jpeg, image/jpg"
                                        className="hidden"
                                        onChange={async (e) => {
                                            const file = e.target.files?.[0];
                                            if (!file) return;

                                            const toastId = toast.loading("Processando imagem...");

                                            try {
                                                // 1. Resize Image to 512x512
                                                const resizeImage = (file: File): Promise<Blob> => {
                                                    return new Promise((resolve, reject) => {
                                                        const img = new Image();
                                                        const objectUrl = URL.createObjectURL(file);
                                                        img.src = objectUrl;
                                                        img.onerror = () => {
                                                            URL.revokeObjectURL(objectUrl);
                                                            reject(new Error("Falha ao carregar a imagem"));
                                                        };
                                                        img.onload = () => {
                                                            // Libera o object URL assim que a imagem é decodificada.
                                                            URL.revokeObjectURL(objectUrl);
                                                            const canvas = document.createElement('canvas');
                                                            canvas.width = 512;
                                                            canvas.height = 512;
                                                            const ctx = canvas.getContext('2d');
                                                            if (!ctx) {
                                                                reject(new Error("Canvas context failed"));
                                                                return;
                                                            }
                                                            // Calculate aspect ratio
                                                            const scale = Math.min(512 / img.width, 512 / img.height);
                                                            const x = (512 / 2) - (img.width / 2) * scale;
                                                            const y = (512 / 2) - (img.height / 2) * scale;

                                                            ctx.drawImage(img, x, y, img.width * scale, img.height * scale);

                                                            canvas.toBlob((blob) => {
                                                                if (blob) resolve(blob);
                                                                else reject(new Error("Blob creation failed"));
                                                            }, 'image/png');
                                                        };
                                                        img.onerror = reject;
                                                    });
                                                };

                                                const resizedBlob = await resizeImage(file);
                                                const providerId = String(settings.providerId || settings.provider?.id || '');
                                                if (!providerId) {
                                                    toast.error("Erro: provedor não identificado.", { id: toastId });
                                                    return;
                                                }
                                                if (!user) {
                                                    toast.error("Sessão expirada.", { id: toastId });
                                                    return;
                                                }

                                                try {
                                                    const token = await user.getIdToken();
                                                    const apiBase = resolvePublicApiBaseUrl(import.meta.env.VITE_API_URL, window.location);
                                                    const response = await fetch(`${apiBase}/admin/providers/${encodeURIComponent(providerId)}/assets`, {
                                                        method: 'POST',
                                                        headers: {
                                                            'Authorization': `Bearer ${token}`,
                                                            'Content-Type': resizedBlob.type || 'image/png',
                                                        },
                                                        body: resizedBlob,
                                                    });
                                                    const rawData = await response.json().catch(() => ({})) as {
                                                        url?: string;
                                                        error?: string | { message?: string };
                                                    };
                                                    if (!response.ok || !rawData.url) {
                                                        const errMsg = typeof rawData.error === 'string'
                                                            ? rawData.error
                                                            : rawData.error?.message;
                                                        throw new Error(errMsg || 'Upload falhou');
                                                    }
                                                    const finalUrl = /^https?:\/\//i.test(rawData.url)
                                                        ? rawData.url
                                                        : `${apiBase}${rawData.url.replace(/^\/api(?=\/)/, '')}`;
                                                    settings.setConfig((prev) => ({
                                                        ...prev,
                                                        logoUrl: finalUrl,
                                                    }));
                                                    toast.success("Logo processada e enviada com sucesso!", { id: toastId });
                                                } catch (error) {
                                                    console.error("Upload error:", error);
                                                    toast.error(`Erro: ${getErrorMessage(error, 'Falha desconhecida')}`, {
                                                        id: toastId,
                                                        duration: 5000,
                                                    });
                                                }

                                            } catch (error) {
                                                console.error("Resize error:", error);
                                                toast.error(`Erro ao processar imagem: ${getErrorMessage(error)}`, { id: toastId });
                                            }
                                        }}
                                    />
                                    <Button
                                        variant="outline"
                                        size="icon"
                                        onClick={() => document.getElementById('logo-upload')?.click()}
                                        title="Fazer Upload de Imagem"
                                        type="button"
                                    >
                                        <Download className="h-4 w-4 rotate-180" />
                                    </Button>
                                </div>
                            </div>
                            <p className="text-xs text-muted-foreground">
                                * A imagem será redimensionada automaticamente para 512x512px (Formato Padrão Android).
                            </p>
                        </div>
                    </div>

                    <div className="flex justify-end pt-2">
                        <Button
                            variant="secondary"
                            size="sm"
                            onClick={async () => {
                                try { await settings.saveConfig(); }
                                catch { /* SettingsContext displays the save error. */ }
                            }}
                            disabled={settings.isSaving || loading}
                        >
                            {settings.isSaving ? <Loader2 className="h-3 w-3 animate-spin mr-2" /> : <Save className="h-3 w-3 mr-2" />}
                            Salvar Configurações
                        </Button>
                    </div>

                    <div className="p-3 bg-muted rounded-md text-xs truncate">
                        <span className="font-semibold block mb-1 text-sm">Status da Logo:</span>
                        {settings.config.logoUrl ? (
                            <div className="flex items-center text-green-600 gap-2">
                                <CheckCircle className="h-4 w-4" /> Configurada
                                <img src={settings.config.logoUrl} alt="Logo do aplicativo" className="h-6 w-6 object-contain ml-2 bg-white/10 rounded" />
                            </div>
                        ) : (
                            <span className="text-destructive flex items-center gap-1">
                                <AlertTriangle className="h-3 w-3" /> Não configurada (Obrigatório)
                            </span>
                        )}
                    </div>

                    <div className="p-3 bg-green-900/20 border border-green-500/30 rounded-md">
                        <span className="font-semibold block mb-1 text-green-500">Formato Loja:</span>
                        Play Store (AAB) + Ofuscação
                    </div>

                    <div className="pt-4 flex flex-col sm:flex-row justify-end gap-3">
                        <Button
                            variant="outline"
                            onClick={() => handleGenerateApk('apk')}
                            disabled={loading || settings.isSaving || (window.location.protocol === 'https:' && runtimeConfig.apkBuilderBaseUrl.startsWith('http:'))}
                            className="w-full sm:w-auto"
                        >
                            {loading ? (
                                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                            ) : (
                                <Smartphone className="mr-2 h-4 w-4" />
                            )}
                            Gerar APK (Teste)
                        </Button>

                        <Button
                            onClick={() => handleGenerateApk('aab')}
                            disabled={loading || settings.isSaving || !settings.config.logoUrl || (window.location.protocol === 'https:' && runtimeConfig.apkBuilderBaseUrl.startsWith('http:'))}
                            className="w-full sm:w-auto bg-green-600 hover:bg-green-700 text-white"
                        >
                            {loading ? (
                                <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                            ) : (
                                <Download className="mr-2 h-4 w-4" />
                            )}
                            Gerar AAB (Play Store)
                        </Button>
                    </div>

                    {buildState.kind === 'running' && (
                        <Alert>
                            <Loader2 className="h-4 w-4 animate-spin" />
                            <AlertTitle>Gerando {buildState.format.toUpperCase()}…</AlertTitle>
                            <AlertDescription>
                                Iniciado às {new Date(buildState.startedAt).toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' })}.
                                Leva alguns minutos. Pode sair desta tela: a geração continua no servidor e o link aparece aqui quando terminar.
                            </AlertDescription>
                        </Alert>
                    )}

                    {lastResult && lastResult.success && (
                        <Alert className="bg-green-500/10 border-green-500/50 text-green-700 dark:text-green-400">
                            <CheckCircle className="h-4 w-4" />
                            <AlertTitle>Sucesso!</AlertTitle>
                            <AlertDescription>
                                O arquivo <strong>{lastResult.format?.toUpperCase() || 'APK'}</strong> foi gerado.
                                <br />
                                Caminho: <code>{lastResult.downloadUrl}</code>
                                <div className="mt-2 p-2 bg-green-900/10 rounded text-sm">
                                    <strong>Versão Gerada:</strong> {lastResult.versionName ? `${lastResult.versionName}` : 'Desconhecida'}
                                    <span className="opacity-75"> (Code: {lastResult.versionCode || '?'})</span>
                                </div>
                                <div className="mt-3 flex gap-2">
                                    <a
                                        href={publicDownloadUrl(lastResult.downloadUrl ?? '')}
                                        target="_blank"
                                        rel="noopener noreferrer"
                                        className="inline-flex items-center gap-2 px-4 py-2 bg-green-600 hover:bg-green-700 text-white rounded-md text-sm font-medium transition-colors"
                                    >
                                        <Download className="h-4 w-4" />
                                        Baixar {lastResult.format?.toUpperCase() || 'APK'}
                                    </a>
                                </div>
                                <div className="mt-2 text-xs opacity-75">
                                    {lastResult.format === 'aab' ? 'Este arquivo está OFUSCADO e pronto para o Google Play Console.' : 'Este arquivo é apenas para testes internos.'}
                                </div>
                            </AlertDescription>
                        </Alert>
                    )}

                    {lastResult && !lastResult.success && (
                        <Alert variant="destructive">
                            <AlertTriangle className="h-4 w-4" />
                            <AlertTitle>Falha na Geração</AlertTitle>
                            <AlertDescription>
                                {lastResult.error || "Erro desconhecido. Verifique os logs do console."}
                            </AlertDescription>
                        </Alert>
                    )}
                </div>
            </SettingsSection>
        </SettingsPage>
    );
}
