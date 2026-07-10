import { useState, useEffect, useCallback, useRef } from 'react';
import { useParams, Outlet, useNavigate } from 'react-router-dom';
import { doc, onSnapshot, setDoc, collection, serverTimestamp } from 'firebase/firestore';
import { db } from '@/firebase/config';
import { toast } from 'sonner';
import { Button } from '@/components/ui/button';
import { ArrowLeft, ExternalLink, Loader2, Save, Smartphone } from 'lucide-react';
import { SettingsContext, ProviderData, ProviderConfigLegacy as ProviderConfig } from '@/contexts/SettingsContext';
import { useAuth } from '@/contexts/AuthContext';

// CACHE BUST 2026-01-29 - Force Refresh
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
                    apiUrl: data.apiUrl,
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

        const cleanConfig = JSON.parse(JSON.stringify(config));

        const requestId = doc(collection(db, 'function_requests')).id;
        const responseDocRef = doc(db, 'function_responses', requestId);

        let unsubscribe: (() => void) | null = null;

        const cleanup = (timeoutId: ReturnType<typeof setTimeout>) => {
            clearTimeout(timeoutId);
            if (unsubscribe) unsubscribe();
        };

        // Timeout de segurança: se a Cloud Function não responder em 35s, desbloqueia o botão
        const timeoutId = setTimeout(() => {
            if (unsubscribe) unsubscribe();
            toast.error('Tempo esgotado: o servidor não respondeu. Tente novamente.', { id: toastId });
            setIsSaving(false);
        }, 35000);

        unsubscribe = onSnapshot(
            responseDocRef,
            (docSnap) => {
                if (docSnap.exists()) {
                    cleanup(timeoutId);
                    const response = docSnap.data();
                    if (response.result) {
                        toast.success("Configurações salvas com sucesso!", { id: toastId });
                    } else {
                        console.error("Erro do Backend:", response.error);
                        toast.error(`Erro ao salvar: ${response.error || 'Erro desconhecido'}`, { id: toastId });
                    }
                    setIsSaving(false);
                }
            },
            (error) => {
                cleanup(timeoutId);
                console.error('[handleSave] Erro no listener function_responses:', error);
                toast.error(`Erro ao salvar: ${error.message}`, { id: toastId });
                setIsSaving(false);
            }
        );

        try {
            await setDoc(doc(db, 'function_requests', requestId), {
                type: 'UPDATE_PROVIDER_CONFIG',
                requesterUid: user.uid,
                createdAt: serverTimestamp(),
                payload: {
                    providerId,
                    config: cleanConfig,
                    requesterUid: user.uid
                }
            });
        } catch (error: any) {
            cleanup(timeoutId);
            toast.error(`Erro ao solicitar a gravação: ${error.message}`, { id: toastId });
            setIsSaving(false);
        }
    }, [providerId, user, config]);

    if (loading) {
        return <div className="flex justify-center items-center h-full"><Loader2 className="animate-spin h-8 w-8 text-primary" /></div>;
    }

    if (!provider) {
        return <div className="text-center p-8"><h2 className="text-xl font-semibold text-destructive">Não foi possível carregar os dados.</h2></div>;
    }

    const providerIdString = providerId ?? 'firebase';
    const providerInitials = (provider.name || providerIdString)
        .split(/\s+/)
        .filter(Boolean)
        .slice(0, 2)
        .map((part: string) => part[0])
        .join('')
        .toUpperCase();
    const providerCnpj = provider.cnpj || provider.document || providerIdString;
    const providerPlan = provider.plan || provider.plano || 'Standard';
    const providerStatus = provider.appStatus || provider.statusApp || 'Publicado';
    const providerAvatarBg = provider.themeColor || config.themeColor || '#10324B';

    return (
        <SettingsContext.Provider value={{ config, setConfig, providerId: providerIdString, provider, loading, saveConfig: handleSave, isSaving }}>
            <div className="flex h-full flex-col gap-5">
                {userRole === 'superAdmin' && (
                    <button
                        type="button"
                        onClick={() => navigate('/provedores')}
                        className="inline-flex w-fit items-center gap-1.5 text-[12.5px] font-semibold text-[#687181] transition-colors hover:text-primary"
                    >
                        <ArrowLeft className="h-3.5 w-3.5" />
                        Voltar para provedores
                    </button>
                )}

                <div className="flex flex-col gap-4 rounded-xl border border-[#E6E9EF] bg-white p-[18px] shadow-[0_1px_2px_rgba(16,24,40,.04)] sm:flex-row sm:items-center">
                    <div
                        className="grid h-[46px] w-[46px] shrink-0 place-items-center rounded-[10px] text-[15px] font-bold text-white"
                        style={{ backgroundColor: providerAvatarBg }}
                    >
                        {providerInitials}
                    </div>
                    <div className="min-w-0 flex-1">
                        <h2 className="truncate text-[16.5px] font-bold tracking-normal text-[#0E1320]">{provider.name || 'Provedor'}</h2>
                        <div className="mt-1 flex flex-wrap items-center gap-2">
                            <span className="rounded-[5px] bg-[#F2F4F7] px-2 py-0.5 font-mono text-[11px] text-[#687181]">{providerCnpj}</span>
                            <span className="rounded-md bg-[#EEF0F4] px-2 py-0.5 text-[11.5px] font-semibold text-[#4A5364]">{providerPlan}</span>
                            <span className="inline-flex items-center gap-1.5 rounded-full bg-emerald-50 px-2.5 py-0.5 text-[11px] font-semibold text-emerald-700">
                                <span className="h-1.5 w-1.5 rounded-full bg-current" />
                                {providerStatus}
                            </span>
                        </div>
                    </div>
                    <div className="flex flex-wrap gap-2 sm:justify-end">
                        <Button variant="outline" className="gap-2">
                            <ExternalLink className="h-3.5 w-3.5" />
                            Ver app publicado
                        </Button>
                        <Button variant="outline" onClick={() => navigate(`${userRole === 'superAdmin' ? `/provedores/${providerIdString}` : '/provedor/personalizacao'}/app-build`)} className="gap-2">
                            <Smartphone className="h-3.5 w-3.5" />
                            Gerar APK
                        </Button>
                        <Button
                            onClick={handleSave}
                            disabled={isSaving}
                            className="gap-2"
                        >
                            {isSaving ? <Loader2 className="h-4 w-4 animate-spin" /> : <Save className="h-4 w-4" />}
                            Salvar alterações
                        </Button>
                    </div>
                </div>

                <Outlet />
            </div>
        </SettingsContext.Provider>
    );
}
