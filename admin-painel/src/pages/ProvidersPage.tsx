// admin-painel/src/pages/ProvidersPage.tsx - VERSÃO CORRIGIDA
import { useState, useEffect, useMemo, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { collection, onSnapshot, doc, setDoc, serverTimestamp } from 'firebase/firestore'; // <-- MUDANÇA AQUI
import { db } from '@/firebase/config'; // <-- MUDANÇA AQUI (removido functions)
import { useAuth } from '@/contexts/AuthContext';
import { toast } from 'sonner';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Card, CardContent, CardDescription, CardHeader, CardTitle, CardFooter } from "@/components/ui/card";
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogHeader, AlertDialogTitle, AlertDialogFooter, AlertDialogTrigger, AlertDialogDescription } from "@/components/ui/alert-dialog";
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Trash2, Loader2, Search, Settings, ServerCrash } from 'lucide-react';
import { Tooltip, TooltipContent, TooltipProvider, TooltipTrigger } from "@/components/ui/tooltip";
import AddProviderDialog from '@/components/AddProviderDialog.tsx';
import EditProviderDialog from '@/components/EditProviderDialog.tsx';
import EmptyState from '@/components/EmptyState.tsx';

interface Provider {
    id: string;
    name?: string;
}

const ITEMS_PER_PAGE = 10;

export default function ProvidersPage() {
    const navigate = useNavigate();
    const { user, userRole } = useAuth();
    const [providers, setProviders] = useState<Provider[]>([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [currentPage, setCurrentPage] = useState(1);

    const fetchProviders = useCallback(() => {
        if (!user || userRole !== 'superAdmin') {
            setLoading(false);
            return () => {};
        }
        setLoading(true);
        const unsubscribe = onSnapshot(collection(db, 'provedores'), (snapshot) => {
            const list = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as Provider));
            setProviders(list);
            setLoading(false);
        }, () => {
            toast.error("Falha ao carregar provedores.");
            setLoading(false);
        });
        return unsubscribe;
    }, [user, userRole]);

    useEffect(() => {
        const unsubscribe = fetchProviders();
        return () => unsubscribe();
    }, [fetchProviders]);

    const filteredProviders = useMemo(() => providers.filter(p =>
        p.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        p.id.toLowerCase().includes(searchTerm.toLowerCase())
    ), [providers, searchTerm]);
    
    const pageCount = Math.ceil(filteredProviders.length / ITEMS_PER_PAGE);
    const paginatedProviders = filteredProviders.slice((currentPage - 1) * ITEMS_PER_PAGE, currentPage * ITEMS_PER_PAGE);

    const handleDelete = async (providerToDelete: Provider) => {
        if (!user) return;
        
        const toastId = toast.loading(`Apagando ${providerToDelete.name}...`);
        
        const requestId = doc(collection(db, 'function_requests')).id;
        const responseDocRef = doc(db, 'function_responses', requestId);

        const unsubscribe = onSnapshot(responseDocRef, (docSnap) => {
            if (docSnap.exists()) {
                const response = docSnap.data();
                unsubscribe();
                if (response.result) {
                    toast.success(response.result.message || "Provedor apagado com sucesso!", { id: toastId });
                    // O onSnapshot da 'fetchProviders' irá atualizar a lista automaticamente
                } else {
                    toast.error(`Erro ao apagar: ${response.error}`, { id: toastId });
                }
            }
        });

        try {
            await setDoc(doc(db, 'function_requests', requestId), {
                type: 'DELETE_PROVIDER',
                requesterUid: user.uid,
                createdAt: serverTimestamp(),
                payload: { providerId: providerToDelete.id }
            });
        } catch (error: any) {
            toast.error(`Falha ao solicitar a exclusão: ${error.message}`, { id: toastId });
            unsubscribe();
        }
    };

    if (loading) return <div className="flex justify-center items-center h-full"><Loader2 className="animate-spin" /></div>;
    if (userRole !== 'superAdmin') return <Card><CardHeader><CardTitle>Acesso Negado</CardTitle></CardHeader></Card>;

    return (
        <TooltipProvider>
            <Card>
                <CardHeader>
                    <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
                        <div>
                            <CardTitle>Gerir Provedores</CardTitle>
                            <CardDescription>Adicione, configure ou remova provedores da plataforma.</CardDescription>
                        </div>
                        <div className="flex items-center gap-2 w-full sm:w-auto">
                            <div className="relative w-full sm:w-64">
                                <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
                                <Input
                                    type="search"
                                    placeholder="Pesquisar por nome ou ID..."
                                    className="pl-8 w-full"
                                    value={searchTerm}
                                    onChange={(e) => { setSearchTerm(e.target.value); setCurrentPage(1); }}
                                />
                            </div>
                            <AddProviderDialog onUpdate={fetchProviders} />
                        </div>
                    </div>
                </CardHeader>
                <CardContent>
                    {filteredProviders.length === 0 ? (
                        <EmptyState 
                            icon={ServerCrash}
                            title="Nenhum provedor encontrado"
                            description="Adicione um novo provedor para começar a gerir."
                        />
                    ) : (
                        <Table>
                            <TableHeader><TableRow><TableHead>Nome</TableHead><TableHead>ID</TableHead><TableHead className="text-right">Ações</TableHead></TableRow></TableHeader>
                            <TableBody>
                                {paginatedProviders.map((p) => (
                                    <TableRow key={p.id}>
                                        <TableCell className="font-medium cursor-pointer hover:underline" onClick={() => navigate(`/provedores/${p.id}`)}>{p.name}</TableCell>
                                        <TableCell className="cursor-pointer hover:underline" onClick={() => navigate(`/provedores/${p.id}`)}>{p.id}</TableCell>
                                        <TableCell className="text-right">
                                            <div className="flex gap-2 justify-end">
                                                <Tooltip>
                                                    <TooltipTrigger asChild><Button variant="outline" size="sm" onClick={() => navigate(`/provedores/${p.id}`)}><Settings className="h-4 w-4" /></Button></TooltipTrigger>
                                                    <TooltipContent><p>Personalizar App</p></TooltipContent>
                                                </Tooltip>
                                                <EditProviderDialog provider={p} onUpdate={fetchProviders} />
                                                <AlertDialog>
                                                    <Tooltip>
                                                        <TooltipTrigger asChild><AlertDialogTrigger asChild><Button variant="destructive" size="sm"><Trash2 className="h-4 w-4" /></Button></AlertDialogTrigger></TooltipTrigger>
                                                        <TooltipContent><p>Apagar Provedor</p></TooltipContent>
                                                    </Tooltip>
                                                    <AlertDialogContent>
                                                        <AlertDialogHeader>
                                                            <AlertDialogTitle>Tem a certeza?</AlertDialogTitle>
                                                            <AlertDialogDescription>Esta ação é irreversível e irá apagar o provedor e todos os seus utilizadores de painel associados.</AlertDialogDescription>
                                                        </AlertDialogHeader>
                                                        <AlertDialogFooter>
                                                            <AlertDialogCancel>Cancelar</AlertDialogCancel>
                                                            <AlertDialogAction onClick={() => handleDelete(p)}>Sim, apagar</AlertDialogAction>
                                                        </AlertDialogFooter>
                                                    </AlertDialogContent>
                                                </AlertDialog>
                                            </div>
                                        </TableCell>
                                    </TableRow>
                                ))}
                            </TableBody>
                        </Table>
                    )}
                </CardContent>
                {filteredProviders.length > 0 && (
                     <CardFooter className="flex items-center justify-between">
                        <span className="text-sm text-muted-foreground">A exibir {paginatedProviders.length} de {filteredProviders.length} provedores.</span>
                        <div className="flex items-center gap-2">
                            <Button variant="outline" size="sm" onClick={() => setCurrentPage(p => Math.max(1, p - 1))} disabled={currentPage === 1}>Anterior</Button>
                            <span className="text-sm">Página {currentPage} de {pageCount > 0 ? pageCount : 1}</span>
                            <Button variant="outline" size="sm" onClick={() => setCurrentPage(p => Math.min(pageCount, p + 1))} disabled={currentPage === pageCount || pageCount === 0}>Próxima</Button>
                        </div>
                    </CardFooter>
                )}
            </Card>
        </TooltipProvider>
    );
};
