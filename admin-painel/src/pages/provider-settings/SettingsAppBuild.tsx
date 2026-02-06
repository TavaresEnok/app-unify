import { useContext, useState } from 'react';
import { SettingsContext } from '@/contexts/SettingsContext';
import { useAuth } from '@/contexts/AuthContext';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import { Loader2, Smartphone, Download, AlertTriangle, CheckCircle } from 'lucide-react';
import { httpsCallable } from 'firebase/functions';
import { functions } from '@/firebase/config';
import { toast } from 'sonner';

export default function AppBuildSettings() {
    // FORCE UPDATE 2
    const { userRole } = useAuth();
    const settings = useContext(SettingsContext);

    // --- SAFETY CHECK (CRITICAL) ---
    // Handle undefined context or missing provider data gracefully
    const providerData = settings?.provider || null;

    if (!settings) {
        console.error("CRITICAL: SettingsContext is undefined in AppBuildSettings");
        return <div className="p-8 text-destructive border border-destructive rounded-md bg-destructive/10">Erro Crítico: Contexto de Configurações não carregado. Recarregue a página.</div>;
    }

    if (!providerData) {
        // If settings exists but provider is null, we are Loading or it failed.
        if (settings.loading) {
            return <div className="flex items-center justify-center p-8 text-muted-foreground"><Loader2 className="animate-spin mr-2" /> Carregando dados do provedor...</div>;
        }
        return <div className="p-8 text-destructive">Erro: Dados do provedor não encontrados.</div>;
    }

    const [loading, setLoading] = useState(false);
    const [lastResult, setLastResult] = useState<any>(null);

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
        if (!providerData?.id) return;

        // Validate Requirements
        const appName = providerData.details?.appName || providerData.name;
        const logoUrl = providerData.logoUrl;

        if (!logoUrl) {
            toast.error("O provedor não tem uma Logo configurada.", {
                description: "Configure a logo na aba 'Aparência' antes de gerar o APK."
            });
            return;
        }

        setLoading(true);
        setLastResult(null);

        try {
            const generateApkFn = httpsCallable(functions, 'generateApk');
            const response = await generateApkFn({
                providerId: providerData.id,
                appName: appName,
                logoUrl: logoUrl,
                format: format
            });

            const result = response.data as any;
            setLastResult({ ...result, format }); // Store format for UI
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
        <div className="space-y-6">
            <div>
                <h3 className="text-lg font-medium">Construção do Aplicativo</h3>
                <p className="text-sm text-muted-foreground">
                    Gere versões do aplicativo para Teste (APK) ou para Loja (AAB).
                </p>
            </div>

            <Card>
                <CardHeader>
                    <CardTitle className="flex items-center gap-2">
                        <Smartphone className="h-5 w-5 text-primary" />
                        Gerador de Versão Android
                    </CardTitle>
                    <CardDescription>
                        Configurações atuais: {providerData.name} ({providerData.id})
                    </CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                    <div className="grid grid-cols-2 gap-4 text-sm">
                        <div className="p-3 bg-muted rounded-md scroll-m-2">
                            <span className="font-semibold block mb-1">Nome do App:</span>
                            {providerData?.details?.appName || providerData?.name || '---'}
                        </div>
                        <div className="p-3 bg-muted rounded-md text-xs truncate">
                            <span className="font-semibold block mb-1 text-sm">Logo URL:</span>
                            {providerData?.logoUrl || 'Não configurada (Erro)'}
                        </div>
                        <div className="p-3 bg-green-900/20 border border-green-500/30 rounded-md">
                            <span className="font-semibold block mb-1 text-green-500">Formato Loja:</span>
                            Play Store (AAB) + Ofuscação
                        </div>
                    </div>

                    <div className="pt-4 flex flex-col sm:flex-row justify-end gap-3">
                        <Button
                            variant="outline"
                            onClick={() => handleGenerateApk('apk')}
                            disabled={loading}
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
                            disabled={loading || !providerData?.logoUrl}
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
                </CardContent>
            </Card>
        </div>
    );
}
