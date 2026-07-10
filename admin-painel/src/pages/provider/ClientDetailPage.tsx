import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { useApi } from '@/hooks/useApi';
import { toast } from 'sonner';
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Loader2, ArrowLeft, UserCircle, AlertTriangle, CreditCard, FileText, Router, Trash2 } from 'lucide-react';
import StatusBadge from '@/components/StatusBadge';

interface ClientData {
    id: string; // ID interno do SGP
    nome: string;
    cpfcnpj: string;
    userStatus: string; // Inferido do contrato retornado pelo proxy
    userPlan: string;
    providerId: string;
    contratos?: any[];
    [key: string]: any; 
}

export default function ClientDetailPage() {
    // Espera o ID interno do SGP na URL (ex: 407)
    const { clientId: sgpClientId } = useParams<{ clientId: string }>(); 
    const navigate = useNavigate();
    const { user, userRole, providerId } = useAuth();
    const { callFunction, loading } = useApi();
    const [client, setClient] = useState<ClientData | null>(null);
    const [isLoadingClient, setIsLoadingClient] = useState(true);

    // 1. Fetch Client Details (Via Proxy SGP, para obter detalhes do cache)
    useEffect(() => {
        // Se o painel não sabe de qual provedor é, ou o ID do cliente está faltando
        if (!sgpClientId || !providerId || !user) {
            setIsLoadingClient(false);
            return;
        }

        const fetchDetails = async () => {
            try {
                // Chamamos o proxy para buscar do CACHE SQLite usando o ID INTERNO do SGP
                const result = await callFunction('SGP_API_PROXY', {
                    providerId: providerId,
                    action: 'get_single', // Ação para buscar cliente único no cache (Proxy ROTA 3)
                    params: { 
                        clientId: sgpClientId // Passamos o ID interno do SGP
                    }
                });
                
                if (result && result.cpfcnpj) {
                    // O resultado do proxy é um objeto cliente (id, nome, cpfcnpj, contratos)
                    // Tentamos inferir status/plano do primeiro contrato, se disponível no cache.
                    const firstContract = result.contratos?.[0] || {};

                    setClient({
                         ...result,
                         id: sgpClientId, // ID SGP
                         providerId: providerId,
                         userStatus: firstContract.contratoStatusDisplay || 'N/A',
                         userPlan: firstContract.servico_plano || 'N/A',
                         // Garantir que a chave cpfcnpj está lá
                         cpfcnpj: result.cpfcnpj,
                         // O campo 'contratos' já vem no result.
                    });
                } else {
                    toast.error("Cliente não encontrado no cache.");
                }
            } catch (error: any) {
                toast.error(error.message || "Falha ao carregar detalhes do cliente do cache SGP.");
            } finally {
                setIsLoadingClient(false);
            }
        };

        fetchDetails();
    }, [sgpClientId, user, providerId, callFunction]);

    const handleDeleteClient = async () => {
        // A exclusão de cliente envolve a remoção do documento na coleção 'clientes' do Firestore,
        // cujo ID é o CPF/CNPJ (limpo), e não o ID SGP. 
        // O cliente.cpfcnpj está no formato que veio do cache SGP (pode ter formatação ou não).

        if (!client || !window.confirm(`Tem certeza que deseja apagar o cliente ${client.nome}? Isso só remove o registro do app/FCM/cache.`)) {
            return;
        }
        
        // CORREÇÃO DE SEGURANÇA: Limpar o CPF/CNPJ antes de tentar apagar o documento do Firestore
        const cleanCpfCnpj = client.cpfcnpj ? client.cpfcnpj.replace(/[^0-9]/g, '') : null;

        if (!cleanCpfCnpj) {
             toast.error("Não foi possível apagar: CPF/CNPJ inválido.");
             return;
        }

        try {
            await callFunction('DELETE_CLIENT', {
                // Ao apagar, passamos o CPF/CNPJ limpo (ID do documento no Firestore)
                clientId: cleanCpfCnpj, 
                providerId: client.providerId, 
            });
            
            navigate('/provedor/clientes');
        } catch (error: any) {
             // O toast de erro já é tratado no useApi
        }
    };
    

    if (isLoadingClient || loading) {
        return <div className="flex justify-center items-center h-full"><Loader2 className="animate-spin" /></div>;
    }

    if (!client) {
        return (
            <Card>
                <CardHeader><CardTitle>Cliente Não Encontrado</CardTitle></CardHeader>
                <CardContent className="flex flex-col items-center gap-4">
                    <AlertTriangle className="h-12 w-12 text-destructive" />
                    <p>O ID do cliente {sgpClientId} é inválido ou não foi encontrado no cache local.</p>
                    <Button onClick={() => navigate(-1)}>Voltar</Button>
                </CardContent>
            </Card>
        );
    }
    
    const clientCpfCnpjDisplay = client.cpfcnpj || 'N/A';
    const isSuperAdmin = userRole === 'superAdmin';
    const firstContract = client.contratos?.[0] || {};
    const diagnostics = Array.isArray(client.diagnosticos || client.diagnostics) ? (client.diagnosticos || client.diagnostics) : [];
    const displayValue = (value: any) => value || value === 0 ? String(value) : "-";

    return (
        <div className="space-y-5">
            <div className="flex flex-col justify-between gap-3 sm:flex-row sm:items-center">
                <Button variant="outline" onClick={() => navigate(-1)} className="gap-2">
                    <ArrowLeft className="h-4 w-4" /> Voltar
                </Button>
                <div className="flex flex-wrap gap-2">
                    <Button variant="destructive" onClick={handleDeleteClient} disabled={loading} className="gap-2">
                        {loading ? <Loader2 className="h-4 w-4 animate-spin" /> : <Trash2 className="h-4 w-4" />}
                        Apagar cliente
                    </Button>
                </div>
            </div>

            <Card className="overflow-hidden">
                <CardHeader className="border-b border-[#EEF0F4]">
                    <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
                        <div className="flex min-w-0 items-center gap-3">
                            <span className="grid h-12 w-12 shrink-0 place-items-center rounded-xl bg-[#0E1320] text-white">
                                <UserCircle className="h-6 w-6" />
                            </span>
                            <div className="min-w-0">
                                <CardTitle className="truncate text-[20px] leading-6">{client.nome}</CardTitle>
                                <div className="mt-2 flex flex-wrap items-center gap-2">
                                    <span className="rounded-full bg-[#EEF0F4] px-2.5 py-0.5 font-mono text-[11px] font-semibold text-[#5B6472]">{clientCpfCnpjDisplay}</span>
                                    <StatusBadge status={client.userStatus || "N/A"} />
                                    <span className="text-[12.5px] text-[#687181]">{displayValue(client.cidade || firstContract.cidade)}</span>
                                </div>
                            </div>
                        </div>
                        <div className="text-left sm:text-right">
                            <p className="text-[11.5px] font-semibold uppercase tracking-[0.06em] text-[#98A1B1]">ID SGP</p>
                            <p className="font-mono text-[13px] font-semibold text-[#1A2233]">{client.id}</p>
                        </div>
                    </div>
                </CardHeader>
            </Card>

            <div className="grid gap-4 lg:grid-cols-3">
                <Card>
                    <CardHeader className="flex-row items-center gap-2 space-y-0 border-b border-[#EEF0F4]">
                        <FileText className="h-4 w-4 text-[#98A1B1]" />
                        <CardTitle>Contrato</CardTitle>
                    </CardHeader>
                    <CardContent className="space-y-4 p-[18px] text-[12.5px]">
                        <div>
                            <p className="mb-1 text-[#98A1B1]">Plano</p>
                            <p className="font-semibold text-[#1A2233]">{displayValue(client.userPlan || firstContract.servico_plano || client.plano)}</p>
                        </div>
                        <div>
                            <p className="mb-1 text-[#98A1B1]">Contrato</p>
                            <p className="font-mono text-[12px] text-[#4A5364]">{displayValue(firstContract.id || firstContract.contrato || firstContract.numero)}</p>
                        </div>
                        <div>
                            <p className="mb-1 text-[#98A1B1]">Provedor</p>
                            <p className="font-semibold text-[#1A2233]">{client.providerId} {isSuperAdmin && `(${client.providerId})`}</p>
                        </div>
                    </CardContent>
                </Card>

                <Card>
                    <CardHeader className="flex-row items-center gap-2 space-y-0 border-b border-[#EEF0F4]">
                        <Router className="h-4 w-4 text-[#98A1B1]" />
                        <CardTitle>Conexão</CardTitle>
                    </CardHeader>
                    <CardContent className="space-y-4 p-[18px] text-[12.5px]">
                        <div>
                            <p className="mb-1 text-[#98A1B1]">Endereço</p>
                            <p className="font-semibold text-[#1A2233]">{displayValue(client.endereco || firstContract.endereco || firstContract.logradouro)}</p>
                        </div>
                        <div>
                            <p className="mb-1 text-[#98A1B1]">ONU / Login</p>
                            <p className="font-mono text-[12px] text-[#4A5364]">{displayValue(firstContract.login || firstContract.usuario || client.login)}</p>
                        </div>
                        <div>
                            <p className="mb-1 text-[#98A1B1]">Status técnico</p>
                            <StatusBadge status={displayValue(firstContract.conexao_status || firstContract.status_conexao || "Não informado")} tone="gray" />
                        </div>
                    </CardContent>
                </Card>

                <Card>
                    <CardHeader className="flex-row items-center gap-2 space-y-0 border-b border-[#EEF0F4]">
                        <CreditCard className="h-4 w-4 text-[#98A1B1]" />
                        <CardTitle>Financeiro</CardTitle>
                    </CardHeader>
                    <CardContent className="space-y-4 p-[18px] text-[12.5px]">
                        <div>
                            <p className="mb-1 text-[#98A1B1]">Situação</p>
                            <StatusBadge status={displayValue(firstContract.financeiro_status || client.financeiro_status || "Em dia")} />
                        </div>
                        <div>
                            <p className="mb-1 text-[#98A1B1]">Vencimento</p>
                            <p className="font-mono text-[12px] text-[#4A5364]">{displayValue(firstContract.vencimento || client.vencimento)}</p>
                        </div>
                        <div>
                            <p className="mb-1 text-[#98A1B1]">Documento</p>
                            <p className="font-mono text-[12px] text-[#4A5364]">{clientCpfCnpjDisplay}</p>
                        </div>
                    </CardContent>
                </Card>
            </div>

            <Card className="overflow-hidden">
                <CardHeader className="border-b border-[#EEF0F4]">
                    <CardTitle>Diagnósticos recentes</CardTitle>
                    <p className="mt-0.5 text-[12.5px] text-[#687181]">Últimos testes associados ao cliente no app.</p>
                </CardHeader>
                <CardContent className="p-0">
                    {diagnostics.length === 0 ? (
                        <div className="py-12 text-center text-[13px] text-[#98A1B1]">Nenhum diagnóstico vinculado a este cliente.</div>
                    ) : (
                        <div className="overflow-x-auto">
                            <div className="min-w-[760px]">
                                <div className="grid grid-cols-[1fr_.8fr_.8fr_.7fr_1fr] gap-x-3 border-b border-[#EEF0F4] bg-[#FAFBFC] px-[18px] py-2.5 text-[11px] font-semibold uppercase tracking-[0.06em] text-[#77808F]">
                                    <span>Data</span>
                                    <span>Download</span>
                                    <span>Upload</span>
                                    <span>Ping</span>
                                    <span>Status</span>
                                </div>
                                {diagnostics.slice(0, 6).map((item: any, index: number) => (
                                    <div key={item.id || index} className="grid grid-cols-[1fr_.8fr_.8fr_.7fr_1fr] items-center gap-x-3 border-b border-[#F2F4F7] px-[18px] py-[11px]">
                                        <span className="font-mono text-[11.5px] text-[#687181]">{displayValue(item.timestamp || item.createdAt || item.data)}</span>
                                        <span className="font-mono text-[12px] text-[#4A5364]">{displayValue(item.downloadSpeed || item.download)} Mbps</span>
                                        <span className="font-mono text-[12px] text-[#4A5364]">{displayValue(item.uploadSpeed || item.upload)} Mbps</span>
                                        <span className="font-mono text-[12px] text-[#4A5364]">{displayValue(item.ping)} ms</span>
                                        <StatusBadge status={displayValue(item.status || item.healthScore || "Registrado")} />
                                    </div>
                                ))}
                            </div>
                        </div>
                    )}
                </CardContent>
            </Card>
        </div>
    );
}
