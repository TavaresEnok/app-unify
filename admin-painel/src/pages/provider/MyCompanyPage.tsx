import { useState, useEffect, useCallback } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { toast } from 'sonner';
import { doc, setDoc, onSnapshot, serverTimestamp, collection, getDoc } from "firebase/firestore";
import { db } from '@/firebase/config';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Loader2 } from 'lucide-react';

interface CompanyDetails {
    razaoSocial?: string;
    nomeFantasia?: string;
    cnpj?: string;
    email?: string;
    telefone?: string;
}

export default function MyCompanyPage() {
    const { user, providerId } = useAuth();
    const [details, setDetails] = useState<CompanyDetails>({});
    const [loading, setLoading] = useState(true);
    const [isSaving, setIsSaving] = useState(false);

    useEffect(() => {
        if (!providerId) return;

        const providerRef = doc(db, 'provedores', providerId);
        const unsubscribe = onSnapshot(providerRef, (docSnap) => {
            if (docSnap.exists()) {
                setDetails(docSnap.data().details || {});
            }
            setLoading(false);
        });

        return () => unsubscribe();
    }, [providerId]);

    const handleDetailChange = (key: keyof CompanyDetails, value: string) => {
        setDetails(prev => ({ ...prev, [key]: value }));
    };

    const handleSave = useCallback(async () => {
        if (!providerId || !user) {
            toast.error("Não foi possível salvar. Tente fazer login novamente.");
            return;
        }

        setIsSaving(true);
        const toastId = toast.loading("Salvando alterações...");

        const requestId = doc(collection(db, 'function_requests')).id;
        const responseDocRef = doc(db, 'function_responses', requestId);

        const unsubscribe = onSnapshot(responseDocRef, (docSnap) => {
            if (docSnap.exists()) {
                unsubscribe();
                const response = docSnap.data();
                if (response.result) {
                    toast.success("Dados da empresa atualizados com sucesso!", { id: toastId });
                } else if (response.error) {
                    toast.error(`Falha ao salvar: ${response.error}`, { id: toastId });
                }
                setIsSaving(false);
            }
        });

        try {
            const providerRef = doc(db, 'provedores', providerId);
            const currentDoc = await getDoc(providerRef);
            const existingDetails = currentDoc.exists() ? currentDoc.data().details : {};

            await setDoc(doc(db, 'function_requests', requestId), {
                type: 'UPDATE_PROVIDER_DETAILS',
                requesterUid: user.uid,
                createdAt: serverTimestamp(),
                payload: {
                    providerId,
                    details: { ...existingDetails, ...details }
                }
            });
        } catch (error: any) {
            toast.error(`Erro ao solicitar a gravação: ${error.message}`, { id: toastId });
            setIsSaving(false);
            unsubscribe();
        }
    }, [providerId, user, details]);

    if (loading) {
        return <div className="flex justify-center items-center h-full"><Loader2 className="animate-spin h-8 w-8" /></div>;
    }

    return (
        <Card className="max-w-4xl mx-auto">
            <CardHeader>
                <CardTitle>Minha Empresa</CardTitle>
                <CardDescription>Gerencie as informações cadastrais do seu provedor.</CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
                <div className="space-y-2">
                    <Label htmlFor="razaoSocial">Razão Social</Label>
                    <Input id="razaoSocial" value={details.razaoSocial || ''} onChange={(e) => handleDetailChange('razaoSocial', e.target.value)} />
                </div>
                <div className="space-y-2">
                    <Label htmlFor="nomeFantasia">Nome Fantasia</Label>
                    <Input id="nomeFantasia" value={details.nomeFantasia || ''} onChange={(e) => handleDetailChange('nomeFantasia', e.target.value)} />
                </div>
                <div className="space-y-2">
                    <Label htmlFor="cnpj">CNPJ</Label>
                    <Input id="cnpj" value={details.cnpj || ''} onChange={(e) => handleDetailChange('cnpj', e.target.value)} />
                </div>
                <div className="space-y-2">
                    <Label htmlFor="email">Email</Label>
                    <Input id="email" type="email" value={details.email || ''} onChange={(e) => handleDetailChange('email', e.target.value)} />
                </div>
                <div className="space-y-2">
                    <Label htmlFor="telefone">Telefone</Label>
                    <Input id="telefone" value={details.telefone || ''} onChange={(e) => handleDetailChange('telefone', e.target.value)} />
                </div>
                <div className="flex justify-end">
                    <Button onClick={handleSave} disabled={isSaving}>
                        {isSaving && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                        Salvar Alterações
                    </Button>
                </div>
            </CardContent>
        </Card>
    );
}
