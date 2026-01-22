import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Loader2, CheckCircle2, XCircle } from 'lucide-react';
import { doc, getDoc, setDoc } from 'firebase/firestore';
import { db } from '@/firebase/config';

export default function FixVibeProvider() {
    const [loading, setLoading] = useState(false);
    const [result, setResult] = useState<{ success: boolean; message: string } | null>(null);

    const handleFix = async () => {
        setLoading(true);
        setResult(null);

        try {
            // 1. Ler o documento original
            console.log('Lendo documento original...');
            const sourceRef = doc(db, 'provedores', '3kdrQFcCkRga234iB1YX');
            const sourceSnap = await getDoc(sourceRef);

            if (!sourceSnap.exists()) {
                throw new Error('Documento original (3kdrQFcCkRga234iB1YX) não encontrado!');
            }

            const data = sourceSnap.data();
            console.log('Dados encontrados:', data);

            // 2. Escrever no novo documento 'vibe'
            console.log('Escrevendo em provedores/vibe...');
            const targetRef = doc(db, 'provedores', 'vibe');
            await setDoc(targetRef, data);

            setResult({
                success: true,
                message: 'Documento copiado com sucesso! Agora o ID "vibe" tem todos os dados.'
            });
        } catch (error: any) {
            console.error('Erro:', error);
            setResult({
                success: false,
                message: error.message || 'Erro ao copiar documento'
            });
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="container mx-auto p-6">
            <Card>
                <CardHeader>
                    <CardTitle>Corrigir Provedor Vibe (Via Cliente)</CardTitle>
                    <CardDescription>
                        Isso vai ler os dados do ID antigo e salvar no ID "vibe" usando sua permissão de admin atual.
                    </CardDescription>
                </CardHeader>
                <CardContent className="space-y-4">
                    <Button
                        onClick={handleFix}
                        disabled={loading}
                        className="w-full"
                    >
                        {loading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                        {loading ? 'Copiando dados...' : 'Copiar Agora'}
                    </Button>

                    {result && (
                        <div className={`p-4 rounded-lg border ${result.success
                                ? 'bg-green-50 border-green-200 text-green-800'
                                : 'bg-red-50 border-red-200 text-red-800'
                            }`}>
                            <div className="flex items-center gap-2">
                                {result.success ? (
                                    <CheckCircle2 className="h-4 w-4" />
                                ) : (
                                    <XCircle className="h-4 w-4" />
                                )}
                                <span>{result.message}</span>
                            </div>
                        </div>
                    )}

                    {result?.success && (
                        <div className="p-4 rounded-lg border bg-yellow-50 border-yellow-200 text-yellow-800">
                            ⚠️ <strong>IMPORTANTE:</strong> Faça <strong>LOGOUT</strong> e <strong>LOGIN</strong> novamente para o sistema carregar os dados novos corretamente.
                        </div>
                    )}
                </CardContent>
            </Card>
        </div>
    );
}
