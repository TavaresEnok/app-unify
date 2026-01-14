import { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { Download, Smartphone, Cpu, Loader2, CheckCircle2, AlertCircle, Info } from "lucide-react";
import { toast } from "sonner";

type BuildArchitecture = 'arm64-v8a' | 'armeabi-v7a' | 'all';

interface BuildOption {
    value: BuildArchitecture;
    label: string;
    description: string;
    devices: string;
    estimatedSize: string;
    recommended?: boolean;
}

const buildOptions: BuildOption[] = [
    {
        value: 'arm64-v8a',
        label: 'Android Recente (64-bit)',
        description: 'Para dispositivos Android 8.0+ (2017 em diante)',
        devices: 'Samsung Galaxy S8+, Xiaomi Mi 6+, Motorola G5+',
        estimatedSize: '~25-35 MB',
        recommended: true,
    },
    {
        value: 'armeabi-v7a',
        label: 'Android Antigo (32-bit)',
        description: 'Para dispositivos Android 4.1+ (mais antigos)',
        devices: 'Samsung Galaxy S4/S5, Moto G 1ª/2ª geração',
        estimatedSize: '~20-30 MB',
    },
    {
        value: 'all',
        label: 'Universal (32-bit + 64-bit)',
        description: 'Compatível com todos os dispositivos Android',
        devices: 'Qualquer dispositivo Android 4.1+',
        estimatedSize: '~50-70 MB',
    },
];

type BuildStatus = 'idle' | 'building' | 'success' | 'error';

export default function AppBuildSettings() {
    const [architecture, setArchitecture] = useState<BuildArchitecture>('arm64-v8a');
    const [buildStatus, setBuildStatus] = useState<BuildStatus>('idle');
    const [buildProgress, setBuildProgress] = useState('');
    const [downloadUrl, setDownloadUrl] = useState<string | null>(null);

    const handleBuild = async () => {
        setBuildStatus('building');
        setBuildProgress('Iniciando build real...');
        setDownloadUrl(null);

        try {
            setBuildProgress('Executando flutter clean...');
            await new Promise(resolve => setTimeout(resolve, 500));

            setBuildProgress('Compilando código Dart...');
            await new Promise(resolve => setTimeout(resolve, 500));

            setBuildProgress('Gerando APK para ' + architecture + '...');

            // Chama API REAL de build
            const response = await fetch('http://168.194.13.18:3000/build-apk', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    secret: 'CHAVE_SECRETA_MUITO_FORTE_12345',
                    architecture,
                    providerId: 'default'
                }),
            });

            if (!response.ok) {
                throw new Error(`Build falhou: ${response.statusText}`);
            }

            const result = await response.json();

            if (!result.success || !result.apkUrl) {
                throw new Error('APK URL não retornada pelo servidor');
            }

            // Define URL do APK com timestamp para evitar cache
            setDownloadUrl(result.apkUrl);
            setBuildStatus('success');
            setBuildProgress(`Build concluído! ${result.timestamp}`);
            toast.success('APK gerado com sucesso!');
        } catch (error: any) {
            setBuildStatus('error');
            setBuildProgress(`Erro: ${error.message || 'Erro desconhecido'}`);
            toast.error('Erro ao gerar APK');
            console.error('[Build Error]', error);
        }
    };

    const handleDownload = () => {
        if (downloadUrl) {
            // Criar link de download e clicar automaticamente
            const link = document.createElement('a');
            link.href = downloadUrl;
            link.download = `app-provedor-${architecture}.apk`;
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
            toast.success('Download iniciado!');
        }
    };

    const selectedOption = buildOptions.find(opt => opt.value === architecture);

    return (
        <div className="space-y-6">
            <Card>
                <CardHeader>
                    <CardTitle className="flex items-center gap-2">
                        <Smartphone className="h-5 w-5" />
                        Gerar APK do Aplicativo
                    </CardTitle>
                    <CardDescription>
                        Compile e baixe o aplicativo Android personalizado para seu provedor.
                        Sem suporte a emulador para reduzir o tamanho do arquivo.
                    </CardDescription>
                </CardHeader>
                <CardContent className="space-y-6">
                    {/* Architecture Selection */}
                    <div className="space-y-4">
                        <Label className="text-base font-semibold">Selecione a Arquitetura</Label>
                        <div className="grid gap-4">
                            {buildOptions.map((option) => (
                                <div
                                    key={option.value}
                                    onClick={() => setArchitecture(option.value)}
                                    className={`relative flex items-start space-x-4 rounded-lg border p-4 transition-colors cursor-pointer hover:bg-accent/50 ${architecture === option.value ? 'border-primary bg-accent/30' : 'border-border'
                                        }`}
                                >
                                    <div className={`mt-1 h-4 w-4 rounded-full border-2 flex items-center justify-center ${architecture === option.value ? 'border-primary' : 'border-muted-foreground'
                                        }`}>
                                        {architecture === option.value && (
                                            <div className="h-2 w-2 rounded-full bg-primary" />
                                        )}
                                    </div>
                                    <div className="flex-1 space-y-1">
                                        <div className="flex items-center gap-2">
                                            <span className="font-medium">{option.label}</span>
                                            {option.recommended && (
                                                <Badge variant="secondary" className="text-xs">Recomendado</Badge>
                                            )}
                                        </div>
                                        <p className="text-sm text-muted-foreground">{option.description}</p>
                                        <div className="flex flex-wrap gap-4 text-xs text-muted-foreground mt-2">
                                            <span className="flex items-center gap-1">
                                                <Cpu className="h-3 w-3" />
                                                {option.devices}
                                            </span>
                                            <span className="flex items-center gap-1">
                                                <Download className="h-3 w-3" />
                                                Tamanho: {option.estimatedSize}
                                            </span>
                                        </div>
                                    </div>
                                </div>
                            ))}
                        </div>
                    </div>

                    {/* Info Box */}
                    <div className="rounded-lg border bg-muted/50 p-4 flex items-start gap-3">
                        <Info className="h-5 w-5 text-muted-foreground mt-0.5" />
                        <div className="text-sm text-muted-foreground">
                            O APK será gerado sem suporte a emulador (x86/x86_64) para reduzir o tamanho.
                            {selectedOption && (
                                <span className="block mt-1 font-medium text-foreground">
                                    Tamanho estimado: {selectedOption.estimatedSize}
                                </span>
                            )}
                        </div>
                    </div>

                    {/* Build Progress */}
                    {buildStatus !== 'idle' && (
                        <div className={`p-4 rounded-lg border ${buildStatus === 'building' ? 'bg-blue-500/10 border-blue-500/30' :
                            buildStatus === 'success' ? 'bg-green-500/10 border-green-500/30' :
                                'bg-red-500/10 border-red-500/30'
                            }`}>
                            <div className="flex items-center gap-3">
                                {buildStatus === 'building' && (
                                    <Loader2 className="h-5 w-5 animate-spin text-blue-500" />
                                )}
                                {buildStatus === 'success' && (
                                    <CheckCircle2 className="h-5 w-5 text-green-500" />
                                )}
                                {buildStatus === 'error' && (
                                    <AlertCircle className="h-5 w-5 text-red-500" />
                                )}
                                <span className={`font-medium ${buildStatus === 'building' ? 'text-blue-500' :
                                    buildStatus === 'success' ? 'text-green-500' :
                                        'text-red-500'
                                    }`}>
                                    {buildProgress}
                                </span>
                            </div>
                        </div>
                    )}

                    {/* Action Buttons */}
                    <div className="flex gap-4">
                        <Button
                            onClick={handleBuild}
                            disabled={buildStatus === 'building'}
                            className="flex-1"
                        >
                            {buildStatus === 'building' ? (
                                <>
                                    <Loader2 className="mr-2 h-4 w-4 animate-spin" />
                                    Gerando APK...
                                </>
                            ) : (
                                <>
                                    <Cpu className="mr-2 h-4 w-4" />
                                    Gerar APK
                                </>
                            )}
                        </Button>

                        {buildStatus === 'success' && downloadUrl && (
                            <Button onClick={handleDownload} variant="outline" className="flex-1">
                                <Download className="mr-2 h-4 w-4" />
                                Baixar APK
                            </Button>
                        )}
                    </div>
                </CardContent>
            </Card>

            {/* Technical Info Card */}
            <Card>
                <CardHeader>
                    <CardTitle className="text-base">Informações Técnicas</CardTitle>
                </CardHeader>
                <CardContent className="space-y-4 text-sm text-muted-foreground">
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <div>
                            <p className="font-medium text-foreground mb-1">arm64-v8a (64-bit)</p>
                            <p>Processadores ARMv8 de 64 bits. Padrão em smartphones desde 2017.</p>
                        </div>
                        <div>
                            <p className="font-medium text-foreground mb-1">armeabi-v7a (32-bit)</p>
                            <p>Processadores ARMv7 de 32 bits. Compatível com dispositivos mais antigos.</p>
                        </div>
                    </div>
                    <div className="pt-2 border-t">
                        <p className="font-medium text-foreground mb-1">Sem Emulador (x86/x86_64)</p>
                        <p>
                            O suporte a emulador foi removido para reduzir o tamanho do APK em até 40%.
                        </p>
                    </div>
                </CardContent>
            </Card>
        </div>
    );
}
