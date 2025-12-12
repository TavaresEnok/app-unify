import { useState } from 'react';
import { doc, getDoc } from 'firebase/firestore';
import { db } from '@/firebase/config';
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { Label } from "@/components/ui/label";
import { Search, CheckCircle, XCircle } from 'lucide-react';
import { toast } from 'sonner';

export default function DebugColorsPage() {
    const [providerId, setProviderId] = useState('');
    const [data, setData] = useState<any>(null);
    const [loading, setLoading] = useState(false);

    const handleCheck = async () => {
        if (!providerId) return;
        setLoading(true);
        setData(null);

        try {
            const docRef = doc(db, "provedores", providerId);
            const docSnap = await getDoc(docRef);

            if (docSnap.exists()) {
                setData(docSnap.data());
                toast.success("Dados recuperados com sucesso.");
            } else {
                toast.error("Provedor não encontrado.");
            }
        } catch (error: any) {
            toast.error("Erro ao buscar: " + error.message);
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="p-8 max-w-2xl mx-auto space-y-6">
            <Card>
                <CardHeader>
                    <CardTitle>Diagnóstico de Cores (Firestore)</CardTitle>
                </CardHeader>
                <CardContent className="space-y-4">
                    <div className="space-y-2">
                        <Label>ID do Provedor</Label>
                        <div className="flex gap-2">
                            <Input 
                                value={providerId} 
                                onChange={(e) => setProviderId(e.target.value)} 
                                placeholder="Ex: vibe" 
                            />
                            <Button onClick={handleCheck} disabled={loading}>
                                <Search className="w-4 h-4 mr-2" />
                                {loading ? "Buscando..." : "Verificar"}
                            </Button>
                        </div>
                    </div>

                    {data && (
                        <div className="mt-6 space-y-6 border-t pt-6">
                            
                            {/* Verificação Específica */}
                            <div className="grid grid-cols-2 gap-4">
                                <div className="p-4 rounded-lg border bg-muted/20">
                                    <Label className="mb-2 block font-bold">cardColor</Label>
                                    <div className="flex items-center gap-2">
                                        {data.cardColor ? (
                                            <>
                                                <CheckCircle className="w-5 h-5 text-green-500" />
                                                <code className="bg-black/10 px-2 py-1 rounded">{data.cardColor}</code>
                                                <div className="w-6 h-6 rounded border shadow-sm" style={{ backgroundColor: data.cardColor }}></div>
                                            </>
                                        ) : (
                                            <>
                                                <XCircle className="w-5 h-5 text-red-500" />
                                                <span className="text-muted-foreground text-sm">Não definido (null/undefined)</span>
                                            </>
                                        )}
                                    </div>
                                </div>

                                <div className="p-4 rounded-lg border bg-muted/20">
                                    <Label className="mb-2 block font-bold">cardTextColor</Label>
                                    <div className="flex items-center gap-2">
                                        {data.cardTextColor ? (
                                            <>
                                                <CheckCircle className="w-5 h-5 text-green-500" />
                                                <code className="bg-black/10 px-2 py-1 rounded">{data.cardTextColor}</code>
                                                <div className="w-6 h-6 rounded border shadow-sm flex items-center justify-center" style={{ backgroundColor: data.cardColor || '#fff' }}>
                                                    <span style={{ color: data.cardTextColor, fontSize: '10px', fontWeight: 'bold' }}>A</span>
                                                </div>
                                            </>
                                        ) : (
                                            <>
                                                <XCircle className="w-5 h-5 text-red-500" />
                                                <span className="text-muted-foreground text-sm">Não definido (null/undefined)</span>
                                            </>
                                        )}
                                    </div>
                                </div>
                            </div>

                            {/* Dados Brutos (JSON) */}
                            <div className="space-y-2">
                                <Label>JSON Completo (Raiz do Documento)</Label>
                                <pre className="bg-slate-950 text-slate-50 p-4 rounded-lg text-xs overflow-auto max-h-96">
                                    {JSON.stringify(data, null, 2)}
                                </pre>
                            </div>
                        </div>
                    )}
                </CardContent>
            </Card>
        </div>
    );
}
