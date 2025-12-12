import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { toast } from 'sonner';
import { doc, setDoc, onSnapshot, serverTimestamp, collection } from "firebase/firestore";
import { db } from '@/firebase/config';
import { Card, CardContent, CardDescription, CardHeader, CardTitle, CardFooter } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Loader2, UserX, Search, RefreshCw } from 'lucide-react';
import EmptyState from '@/components/EmptyState';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';

interface SgpClient {
    id: number;
    nome: string;
    cpfcnpj: string;
    contratos: { id: number; status: string }[];
}

const ITEMS_PER_PAGE = 25;

// Hook para "atrasar" a busca e não fazer uma requisição a cada tecla digitada
function useDebounce(value: string, delay: number) {
    const [debouncedValue, setDebouncedValue] = useState(value);
    useEffect(() => {
        const handler = setTimeout(() => {
            setDebouncedValue(value);
        }, delay);
        return () => {
            clearTimeout(handler);
        };
    }, [value, delay]);
    return debouncedValue;
}

export default function ProviderClientsPage() {
    const navigate = useNavigate();
    const { user, providerId } = useAuth();
    const [clients, setClients] = useState<SgpClient[]>([]);
    const [loading, setLoading] = useState(true);
    const [isSyncing, setIsSyncing] = useState(false);
    const [searchTerm, setSearchTerm] = useState('');
    const [currentPage, setCurrentPage] = useState(1);
    const [totalClients, setTotalClients] = useState(0);

    const debouncedSearchTerm = useDebounce(searchTerm, 300); // Aguarda 300ms após o usuário parar de digitar
    const pageCount = Math.ceil(totalClients / ITEMS_PER_PAGE);

    const callProxy = useCallback(async (action: 'sync' | 'get', page = 1, search = '') => {
        if (!providerId || !user) return;

        const isSyncAction = action === 'sync';
        if (isSyncAction) {
            setIsSyncing(true);
            toast.info("Iniciando sincronização... Isso pode levar vários minutos. Por favor, aguarde.");
        } else {
            setLoading(true);
        }

        const offset = (page - 1) * ITEMS_PER_PAGE;
        const requestId = doc(collection(db, 'function_requests')).id;
        const responseDocRef = doc(db, 'function_responses', requestId);

        const unsubscribe = onSnapshot(responseDocRef, (docSnap) => {
            if (docSnap.exists()) {
                unsubscribe();
                const response = docSnap.data();

                if (response.error) {
                    toast.error(isSyncAction ? "Falha na sincronização" : "Falha ao carregar clientes", { description: response.error });
                } else if (response.result) {
                    if (isSyncAction) {
                        toast.success("Sincronização concluída!", { description: `${response.result.count} clientes foram salvos.` });
                        setSearchTerm(''); // Limpa a busca após sincronizar
                        setCurrentPage(1);
                        callProxy('get', 1, ''); // Recarrega a primeira página
                    } else {
                        setClients(response.result.clientes || []);
                        setTotalClients(response.result.paginacao?.total || 0);
                    }
                }
                setLoading(false);
                setIsSyncing(false);
            }
        });

        try {
            await setDoc(doc(db, 'function_requests', requestId), {
                type: 'SGP_API_PROXY',
                requesterUid: user.uid,
                createdAt: serverTimestamp(),
                payload: {
                    providerId,
                    requesterUid: user.uid,
                    action: action,
                    params: isSyncAction ? {
                        limit: 100,
                        offset: 0,
                        contrato_status: 1,
                        omitir_titulos: 1
                    } : {
                        limit: ITEMS_PER_PAGE,
                        offset: offset,
                        searchTerm: search
                    }
                }
            });
        } catch (error: any) {
            toast.error("Erro ao disparar a função.", { description: error.message });
            setLoading(false);
            setIsSyncing(false);
            unsubscribe();
        }
    }, [providerId, user]);

    // Efeito para buscar os clientes do cache ao carregar ou mudar de página/busca
    useEffect(() => {
        if (!isSyncing) {
            callProxy('get', currentPage, debouncedSearchTerm);
        }
    }, [currentPage, debouncedSearchTerm, callProxy, isSyncing]);

    // Handler para o input de busca
    const handleSearchChange = (event: React.ChangeEvent<HTMLInputElement>) => {
        setSearchTerm(event.target.value);
        setCurrentPage(1); // Volta para a primeira página sempre que uma nova busca é feita
    };

    if (loading && clients.length === 0) {
        return (
            <div className="flex flex-col justify-center items-center h-full text-center">
                <Loader2 className="animate-spin h-8 w-8 mb-4" />
                <p className="text-lg font-semibold">Carregando clientes do cache...</p>
            </div>
        );
    }

    return (
        <Card>
            <CardHeader>
                <div className="flex flex-col sm:flex-row items-center justify-between gap-4">
                    <div>
                        <CardTitle>Clientes Ativos (SGP)</CardTitle>
                        <CardDescription>
                            {totalClients > 0 ? `Encontrados ${totalClients} clientes no total.` : "Nenhum cliente sincronizado."}
                        </CardDescription>
                    </div>
                    <div className="flex w-full sm:w-auto items-center gap-4">
                        <div className="relative flex-grow sm:flex-grow-0 sm:w-64">
                            <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
                            <Input
                                type="search"
                                placeholder={`Pesquisar em ${totalClients} clientes...`}
                                className="pl-8 w-full"
                                value={searchTerm}
                                onChange={handleSearchChange}
                            />
                        </div>
                        <Button onClick={() => callProxy('sync')} disabled={isSyncing} variant="outline">
                            {isSyncing ? <Loader2 className="mr-2 h-4 w-4 animate-spin"/> : <RefreshCw className="mr-2 h-4 w-4" />}
                            Sincronizar
                        </Button>
                    </div>
                </div>
            </CardHeader>
            <CardContent>
                {loading ? (
                    <div className="flex justify-center items-center h-64"><Loader2 className="animate-spin h-8 w-8" /></div>
                ) : clients.length === 0 ? (
                    <EmptyState
                        icon={UserX}
                        title={searchTerm ? "Nenhum resultado para sua busca" : "Nenhum Cliente no Cache"}
                        description={searchTerm ? `Não foram encontrados clientes com o termo "${searchTerm}". Limpe a busca para ver todos.` : "Clique em 'Sincronizar' para buscar os dados do SGP."}
                    />
                ) : (
                    <Table>
                        <TableHeader>
                            <TableRow>
                                <TableHead>ID</TableHead>
                                <TableHead>Nome</TableHead>
                                <TableHead>CPF/CNPJ</TableHead>
                                <TableHead>Contratos</TableHead>
                            </TableRow>
                        </TableHeader>
                        <TableBody>
                            {clients.map((client) => (
                                <TableRow 
                                    key={client.id} 
                                    className="cursor-pointer hover:bg-muted" 
                                    // CORREÇÃO: Passa o CPF/CNPJ (ID do documento no Firestore)
                                    onClick={() => navigate(`/provedor/clientes/${client.cpfcnpj}`)}
                                >
                                    <TableCell>{client.id}</TableCell>
                                    <TableCell className="font-medium">{client.nome}</TableCell>
                                    <TableCell>{client.cpfcnpj}</TableCell>
                                    <TableCell>{client.contratos && client.contratos.map((c: any) => c.id).join(', ')}</TableCell>
                                </TableRow>
                            ))}
                        </TableBody>
                    </Table>
                )}
            </CardContent>
            {pageCount > 1 && (
                <CardFooter className="flex items-center justify-between">
                    <span className="text-sm text-muted-foreground">
                        Página {currentPage} de {pageCount}
                    </span>
                    <div className="flex items-center gap-2">
                        <Button variant="outline" size="sm" onClick={() => setCurrentPage(p => Math.max(1, p - 1))} disabled={currentPage === 1 || loading}>Anterior</Button>
                        <Button variant="outline" size="sm" onClick={() => setCurrentPage(p => Math.min(pageCount, p + 1))} disabled={currentPage === pageCount || loading}>Próxima</Button>
                    </div>
                </CardFooter>
            )}
        </Card>
    );
}
