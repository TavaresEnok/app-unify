import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { useApi } from '@/hooks/useApi';
import { toast } from 'sonner';
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Loader2, ArrowLeft, UserCircle, AlertTriangle } from 'lucide-react';

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
    
    // O ID na URL é o ID SGP, mas o CPF/CNPJ formatado é exibido
    const clientCpfCnpjDisplay = client.cpfcnpj || 'N/A';
    const isSuperAdmin = userRole === 'superAdmin';

    return (
        <div className="flex flex-col gap-6">
            <div className="flex items-center justify-between">
                <Button variant="outline" onClick={() => navigate(-1)} className="gap-2">
                    <ArrowLeft className="h-4 w-4" /> Voltar
                </Button>
                <Button variant="destructive" onClick={handleDeleteClient} disabled={loading}>
                     {loading ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : "Apagar Cliente (App/FCM)"}
                </Button>
            </div>

            <Card>
                <CardHeader className="flex flex-row items-center space-y-0 pb-2">
                    <UserCircle className="h-6 w-6 mr-3 text-primary" />
                    <CardTitle className="text-2xl">{client.nome}</CardTitle>
                </CardHeader>
                <CardContent className="grid gap-4 pt-4">
                    <div className="grid grid-cols-2 gap-4">
                        <div className="space-y-1">
                            <p className="text-sm font-medium text-muted-foreground">CPF/CNPJ</p>
                            <p className="font-bold">{clientCpfCnpjDisplay}</p>
                        </div>
                        <div className="space-y-1">
                            <p className="text-sm font-medium text-muted-foreground">Status</p>
                            <p className={`font-bold ${client.userStatus === 'Ativo' ? 'text-green-500' : 'text-red-500'}`}>{client.userStatus}</p>
                        </div>
                    </div>
                    <div className="grid grid-cols-2 gap-4">
                        <div className="space-y-1">
                            <p className="text-sm font-medium text-muted-foreground">Plano</p>
                            <p className="font-bold">{client.userPlan}</p>
                        </div>
                        <div className="space-y-1">
                            <p className="text-sm font-medium text-muted-foreground">ID SGP / Provedor</p>
                            <p className="font-bold">{client.id} / {client.providerId} {isSuperAdmin && `(${client.providerId})`}</p>
                        </div>
                    </div>

                    <h3 className="text-xl font-semibold mt-4 border-t pt-4">Dados Técnicos (Cache SGP)</h3>
                    
                    <Card className="bg-muted/50 p-4">
                        <pre className="text-xs overflow-auto max-h-[300px]">
                            {JSON.stringify(client.contratos || client, null, 2)}
                        </pre>
                    </Card>

                </CardContent>
            </Card>
        </div>
    );
}
