import { useState } from 'react';
import { useSettings } from '@/contexts/SettingsContext';
import { useAuth } from '@/contexts/AuthContext';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import { Loader2, Smartphone, Download, AlertTriangle, CheckCircle, Save } from 'lucide-react';
import { httpsCallable } from 'firebase/functions';
import { functions } from '@/firebase/config';
import { toast } from 'sonner';
import { SettingsPage, SettingsSection } from '@/components/settings/SettingsPage';

// FINAL-FINAL FIX - RENAMED FILE
export default function AndroidBuilderPage() {
    const { userRole, user } = useAuth();
    const settings = useSettings();
    const [loading, setLoading] = useState(false);
    const [lastResult, setLastResult] = useState<any>(null);

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
        const appName = providerData?.details?.appName || providerData?.name;
        const logoUrl = providerData?.logoUrl;

        if (!logoUrl) {
            toast.error("O provedor não tem uma Logo configurada.", {
                description: "Configure a logo na aba 'Aparência' antes de gerar o APK."
            });
            return;
        }

        setLoading(true);
        setLastResult(null);

        try {
            if (!user) {
                throw new Error("Usuário não autenticado");
            }
            const token = await user.getIdToken();

            // Call APK Builder service (runs on host, not in Docker)
            const API_URL = 'http://168.194.13.18:8035';
            const response = await fetch(`${API_URL}/generate-apk`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${token}`
                },
                body: JSON.stringify({
                    providerId,
                    appName,
                    logoUrl,
                    format
                })
            });

            const result = await response.json();

            if (!response.ok) {
                throw new Error(result.error || `HTTP ${response.status}`);
            }

            setLastResult({ ...result, format });
            toast.success(`${format.toUpperCase()} Gerado com Sucesso!`, {
                description: "O arquivo está disponível na pasta pública do servidor."
            });
        } catch (error: any) {
            console.error(error);
            toast.error(`Erro ao gerar ${format.toUpperCase()}`, {
                description: error.message
            });
            setLastResult({ success: false, error: error.message });
        } finally {
            setLoading(false);
        }
    };



    return (
        <SettingsPage
            title="Gerar app"
            description="Gere versões do aplicativo para teste (APK) ou para loja (AAB)."
            icon={Smartphone}
        >

            {window.location.protocol === 'https:' && (
                <Alert variant="destructive" className="bg-amber-500/10 text-amber-600 border-amber-500/50 dark:text-amber-400">
                    <AlertTriangle className="h-4 w-4" />
                    <AlertTitle>Restrição de Segurança do Navegador</AlertTitle>
                    <AlertDescription>
                        Você está acessando pelo painel em Nuvem (HTTPS).<br />
                        Por motivos de segurança, o navegador bloqueia a conexão com o gerador de APK local (HTTP).<br />
                        <br />
                        <strong>Para gerar o APK, acesse o painel localmente:</strong><br />
                        <a href="http://168.194.13.18:8031" target="_blank" className="font-mono underline font-bold">
                            http://168.194.13.18:8031
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
                            <label className="text-sm font-medium">Nome do Aplicativo</label>
                            <div className="flex gap-2">
                                <Input
                                    value={settings.config?.details?.appName || settings.config?.name || ''}
                                    onChange={(e) => {
                                        const val = e.target.value;
                                        settings.setConfig((prev: any) => ({
                                            ...prev,
                                            details: { ...(prev.details || {}), appName: val }
                                        }));
                                    }}
                                    placeholder="Ex: Minha Net"
                                />
                            </div>
                            <p className="text-xs text-muted-foreground">Nome que aparecerá instalado no celular.</p>
                        </div>

                        <div className="space-y-2">
                            <label className="text-sm font-medium">Logo do App (Icone)</label>
                            <div className="flex gap-2">
                                <div className="flex-1">
                                    <Input
                                        value={settings.config?.details?.logoUrl || settings.config?.logoUrl || ''}
                                        onChange={(e) => {
                                            const val = e.target.value;
                                            settings.setConfig((prev: any) => ({
                                                ...prev,
                                                details: { ...(prev.details || {}), logoUrl: val },
                                                logoUrl: val // Sync root for backward compatibility
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
                                                        img.src = URL.createObjectURL(file);
                                                        img.onload = () => {
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

                                                // 2. Convert to Base64 and call Cloud Function
                                                const reader = new FileReader();
                                                reader.readAsDataURL(resizedBlob);
                                                reader.onloadend = async () => {
                                                    const base64data = reader.result as string | null;
                                                    const providerId = settings.providerId || settings.provider?.id;
                                                    if (!base64data || typeof base64data !== 'string') {
                                                        toast.error("Erro: imagem inválida (base64 vazio).", { id: toastId });
                                                        return;
                                                    }
                                                    if (!providerId) {
                                                        toast.error("Erro: provedor não identificado.", { id: toastId });
                                                        return;
                                                    }

                                                    try {
                                                        const uploadFn = httpsCallable(functions, 'uploadProviderLogo');
                                                        const result = await uploadFn({
                                                            imageBase64: base64data,
                                                            providerId
                                                        });

                                                        const data = result.data as any;
                                                        if (data.success) {
                                                            // Update State
                                                            settings.setConfig((prev: any) => ({
                                                                ...prev,
                                                                logoUrl: data.url,
                                                                details: { ...(prev.details || {}), logoUrl: data.url }
                                                            }));

                                                            toast.success("Logo processada e enviada com sucesso!", { id: toastId });
                                                        } else {
                                                            throw new Error(data.error || 'Upload falhou');
                                                        }
                                                    } catch (error: any) {
                                                        console.error("Upload error:", error);
                                                        toast.error(`Erro: ${error.message || error.code || 'Falha desconhecida'}`, {
                                                            id: toastId,
                                                            duration: 5000
                                                        });
                                                    }
                                                };
                                                reader.onerror = () => {
                                                    toast.error("Erro ao ler arquivo", { id: toastId });
                                                };

                                            } catch (error: any) {
                                                console.error("Resize error:", error);
                                                toast.error(`Erro ao processar imagem: ${error.message}`, { id: toastId });
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
                            onClick={() => void settings.saveConfig()}
                            disabled={settings.isSaving}
                        >
                            {settings.isSaving ? <Loader2 className="h-3 w-3 animate-spin mr-2" /> : <Save className="h-3 w-3 mr-2" />}
                            Salvar Configurações
                        </Button>
                    </div>

                    <div className="p-3 bg-muted rounded-md text-xs truncate">
                        <span className="font-semibold block mb-1 text-sm">Status da Logo:</span>
                        {providerData?.logoUrl ? (
                            <div className="flex items-center text-green-600 gap-2">
                                <CheckCircle className="h-4 w-4" /> Configurada
                                <img src={providerData.logoUrl} className="h-6 w-6 object-contain ml-2 bg-white/10 rounded" />
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
                            disabled={loading || window.location.protocol === 'https:'}
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
                            disabled={loading || !providerData?.logoUrl || window.location.protocol === 'https:'}
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

                    {lastResult && lastResult.success && (
                        <Alert className="bg-green-500/10 border-green-500/50 text-green-700 dark:text-green-400">
                            <CheckCircle className="h-4 w-4" />
                            <AlertTitle>Sucesso!</AlertTitle>
                            <AlertDescription>
                                O arquivo <strong>{lastResult.format?.toUpperCase() || 'APK'}</strong> foi gerado.
                                <br />
                                Caminho: <code>public_apks/app_{providerData.details?.appName?.replace(/[^a-zA-Z0-9]/g, '_') || 'app'}.{lastResult.format || 'apk'}</code>
                                <div className="mt-2 p-2 bg-green-900/10 rounded text-sm">
                                    <strong>Versão Gerada:</strong> {lastResult.versionName ? `${lastResult.versionName}` : 'Desconhecida'}
                                    <span className="opacity-75"> (Code: {lastResult.versionCode || '?'})</span>
                                </div>
                                <div className="mt-3 flex gap-2">
                                    <a
                                        href={`http://168.194.13.18:8032${lastResult.downloadUrl}`}
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
