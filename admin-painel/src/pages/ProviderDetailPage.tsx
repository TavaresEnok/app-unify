import { useState, useEffect, useCallback, useRef } from 'react';
import { useParams, Outlet, useNavigate } from 'react-router-dom';
import { doc, onSnapshot, setDoc, collection, serverTimestamp } from 'firebase/firestore';
import { db } from '@/firebase/config';
import { toast } from 'sonner';
import { Button } from '@/components/ui/button';
import { Loader2, Save } from 'lucide-react';
import { SettingsContext, ProviderData, ProviderConfig } from '@/contexts/SettingsContext';
import { useAuth } from '@/contexts/AuthContext';
import Breadcrumbs from '@/components/Breadcrumbs';

export default function ProviderDetailPage() {
    const { providerId: providerIdFromParams } = useParams<{ providerId: string }>();
    const { user, userRole, providerId: providerIdFromAuth } = useAuth();
    const navigate = useNavigate();

    const providerId = userRole === 'superAdmin' ? providerIdFromParams : providerIdFromAuth;

    const [provider, setProvider] = useState<ProviderData | null>(null);
    const [config, setConfig] = useState<ProviderConfig>({});
    const [loading, setLoading] = useState(true);
    const [isSaving, setIsSaving] = useState(false);
    
    const hasLoadedInitialConfig = useRef(false);

    useEffect(() => {
        if (!providerId) {
            toast.error("ID do provedor não identificado.");
            setLoading(false);
            return;
        }

        hasLoadedInitialConfig.current = false;

        const docRef = doc(db, "provedores", providerId);
        const unsubscribe = onSnapshot(docRef, (docSnap) => {
            if (docSnap.exists()) {
                const data = docSnap.data() as ProviderData;
                setProvider(data);
                
                const mergedConfig = {
                    themeColor: data.themeColor,
                    secondaryColor: data.secondaryColor,
                    logoUrl: data.logoUrl,
                    socialNetworks: data.socialNetworks,
                    integrations: data.integrations,
                    menuConfig: data.menuConfig,
                    tips: data.tips || data.dicas, 
                    faq: data.faq,
                    imageCarousel: data.imageCarousel,
                    ...(data.config || {})
                };

                if (!hasLoadedInitialConfig.current) {
                    setConfig(mergedConfig);
                    hasLoadedInitialConfig.current = true; 
                }
            } else {
                toast.error("Provedor não encontrado.");
                if (userRole === 'superAdmin') navigate('/provedores');
            }
            setLoading(false);
        }, (error) => {
            toast.error(`Erro ao buscar provedor: ${error.message}`);
            setLoading(false);
        });
        return () => unsubscribe();
    }, [providerId, navigate, userRole]);

    const handleSave = useCallback(async () => {
        if (!providerId || !user) return;
        setIsSaving(true);
        const toastId = toast.loading("Salvando configurações...");
        
        // --- CORREÇÃO DO ERRO FIREBASE ---
        // Remove qualquer campo 'undefined' do objeto config antes de enviar.
        // O Firebase não aceita 'undefined'. O JSON stringify/parse é um truque rápido para limpar isso.
        const cleanConfig = JSON.parse(JSON.stringify(config));
        // ----------------------------------

        const requestId = doc(collection(db, 'function_requests')).id;
        const responseDocRef = doc(db, 'function_responses', requestId);

        const unsubscribe = onSnapshot(responseDocRef, (docSnap) => {
            if (docSnap.exists()) {
                unsubscribe();
                const response = docSnap.data();
                if (response.result) {
                    toast.success("Configurações salvas com sucesso!", { id: toastId });
                } else {
                    console.error("Erro do Backend:", response.error);
                    toast.error(`Erro ao salvar. Verifique o console.`, { id: toastId });
                }
                setIsSaving(false);
            }
        });

        try {
            await setDoc(doc(db, 'function_requests', requestId), {
                type: 'UPDATE_PROVIDER_CONFIG',
                requesterUid: user.uid,
                createdAt: serverTimestamp(),
                payload: { 
                    providerId, 
                    config: cleanConfig, // Envia a versão limpa
                    requesterUid: user.uid 
                }
            });
        } catch (error: any) {
            toast.error(`Erro ao solicitar a gravação: ${error.message}`);
            setIsSaving(false);
            unsubscribe();
        }
    }, [providerId, user, config]);

    if (loading) {
        return <div className="flex justify-center items-center h-full"><Loader2 className="animate-spin h-8 w-8 text-primary" /></div>;
    }

    if (!provider) {
        return <div className="text-center p-8"><h2 className="text-xl font-semibold text-destructive">Não foi possível carregar os dados.</h2></div>;
    }

    const providerIdString = providerId ?? 'firebase'; 

    return (
        <SettingsContext.Provider value={{ config, setConfig, providerId: providerIdString, provider, loading, saveConfig: handleSave, isSaving }}>
            <div className="space-y-6 h-full flex flex-col">
                <div className="flex flex-col gap-4 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60 sticky top-0 z-40 py-2 -mx-4 px-4 border-b md:static md:border-none md:p-0 md:mx-0">
                    <div className="flex items-center justify-between">
                        <div>
                            <Breadcrumbs />
                            <h1 className="text-2xl md:text-3xl font-bold truncate">Personalização: {provider.name}</h1>
                        </div>
                        <Button 
                            onClick={handleSave} 
                            disabled={isSaving} 
                            className={`shrink-0 shadow-lg transition-all ${isSaving ? 'opacity-80' : 'hover:ring-2 hover:ring-primary/50'}`}
                        >
                            {isSaving ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <Save className="mr-2 h-4 w-4" />}
                            <span className="hidden sm:inline">Salvar Alterações</span>
                            <span className="sm:hidden">Salvar</span>
                        </Button>
                    </div>
                </div>

                <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 items-start flex-1">
                    <div className="lg:col-span-2 space-y-6 order-2 lg:order-1 pb-10">
                        <Outlet />
                    </div>
                </div>
            </div>
        </SettingsContext.Provider>
    );
}
