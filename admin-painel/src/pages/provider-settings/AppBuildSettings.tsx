import { useState } from 'react';
import { useOutletContext } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert';
import { Loader2, Smartphone, Download, AlertTriangle, CheckCircle } from 'lucide-react';
import { httpsCallable } from 'firebase/functions';
import { functions } from '@/firebase/config';
import { toast } from 'sonner';

export default function AppBuildSettings() {
    const { userRole } = useAuth();
    const { providerData } = useOutletContext<any>();
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

    const handleGenerateApk = async () => {
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
                logoUrl: logoUrl
            });

            const result = response.data as any;
            setLastResult(result);
            toast.success("APK Gerado com Sucesso!", {
                description: "O arquivo está disponível na pasta pública do servidor."
            });
        } catch (error: any) {
            console.error(error);
            toast.error("Erro ao gerar APK", {
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
                <h3 className="text-lg font-medium">Construção do Aplicativo (APK)</h3>
                <p className="text-sm text-muted-foreground">
                    Ferramenta interna para gerar e assinar o aplicativo Android deste provedor.
                </p>
            </div>

            <Card>
                <CardHeader>
                    <CardTitle className="flex items-center gap-2">
                        <Smartphone className="h-5 w-5 text-primary" />
                        Gerador de Versão Android
                    </CardTitle>
                    <CardDescription>
                        Este processo irá criar um APK único usando as configurações atuais (Logo, Nome, ID).
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
                        <div className="p-3 bg-muted rounded-md">
                            <span className="font-semibold block mb-1">ID Interno:</span>
                            {providerData?.id}
                        </div>
                    </div>

                    <div className="pt-4 flex justify-end">
                        <Button
                            onClick={handleGenerateApk}
                            disabled={loading || !providerData?.logoUrl}
                            className="w-full sm:w-auto"
                        >
                            {loading ? (
                                <>
                                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                                    Gerando APK (Aguarde ~2min)...
                                </>
                            ) : (
                                <>
                                    <Smartphone className="mr-2 h-4 w-4" />
                                    Gerar APK Agora
                                </>
                            )}
                        </Button>
                    </div>

                    {lastResult && lastResult.success && (
                        <Alert className="bg-green-500/10 border-green-500/50 text-green-700 dark:text-green-400">
                            <CheckCircle className="h-4 w-4" />
                            <AlertTitle>Sucesso!</AlertTitle>
                            <AlertDescription>
                                O APK foi gerado e salvo no servidor.
                                <br />
                                Neste MVP, o arquivo fica em: <code>public_apks/app_{providerData.details?.appName?.replace(/[^a-zA-Z0-9]/g, '_') || 'app'}.apk</code>
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
