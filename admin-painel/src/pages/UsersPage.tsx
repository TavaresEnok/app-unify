// admin-painel/src/pages/UsersPage.tsx - VERSÃO FINAL MIGRADA
import { useState, useEffect, useMemo, useCallback } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { toast } from 'sonner';
import { doc, setDoc, onSnapshot, serverTimestamp, collection } from "firebase/firestore";
import { db } from '@/firebase/config';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Card, CardContent, CardDescription, CardHeader, CardTitle, CardFooter } from "@/components/ui/card";
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { Loader2, Trash2, UserX, Search } from 'lucide-react';
import AddAdminDialog from '@/components/AddAdminDialog.tsx';
import SetSuperAdminDialog from '@/components/SetSuperAdminDialog.tsx'; // <-- ADICIONADO
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle, AlertDialogTrigger } from "@/components/ui/alert-dialog";
import EmptyState from '@/components/EmptyState.tsx';

interface AdminUser {
    uid: string;
    email?: string;
    superAdmin: boolean;
    providerId?: string;
}

const ITEMS_PER_PAGE = 10;

export default function UsersPage() {
    const { user, userRole } = useAuth();
    const [users, setUsers] = useState<AdminUser[]>([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [currentPage, setCurrentPage] = useState(1);

    const fetchUsers = useCallback(() => {
        if (userRole !== 'superAdmin' || !user) {
            setLoading(false);
            return () => { };
        }
        setLoading(true);
        let responded = false; // Flag mutável para evitar stale closure
        const requestId = doc(collection(db, 'function_requests')).id;
        const responseDocRef = doc(db, 'function_responses', requestId);

        const unsubscribe = onSnapshot(responseDocRef, (docSnap) => {
            if (docSnap.exists()) {
                responded = true;
                const response = docSnap.data();
                if (response.result && response.result.users) {
                    setUsers(response.result.users);
                } else if (response.error) {
                    toast.error(`Falha ao carregar utilizadores: ${response.error}`);
                }
                setLoading(false);
                unsubscribe();
            }
        });

        const triggerFunction = async () => {
            try {
                const requestDocRef = doc(db, 'function_requests', requestId);
                await setDoc(requestDocRef, {
                    type: 'LIST_ADMIN_USERS',
                    requesterUid: user.uid,
                    createdAt: serverTimestamp(),
                });
            } catch (error: any) {
                toast.error(`Falha ao solicitar lista de utilizadores: ${error.message}`);
                setLoading(false);
                unsubscribe();
            }
        };

        // Timeout de segurança (15 segundos) — usa flag `responded` em vez de `loading`
        const timeoutId = setTimeout(() => {
            if (!responded) {
                setLoading(false);
                toast.error("O servidor demorou muito para responder.", {
                    description: "Verifique se as Funções Cloud foram implantadas (deploy)."
                });
                if (unsubscribe) unsubscribe();
            }
        }, 15000);

        triggerFunction();

        return () => {
            clearTimeout(timeoutId);
            unsubscribe();
        };
    }, [userRole, user]);

    useEffect(() => {
        const unsubscribe = fetchUsers();
        return () => {
            if (unsubscribe) unsubscribe();
        };
    }, [fetchUsers]);

    const filteredUsers = useMemo(() => users.filter(u =>
        u.email?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        u.providerId?.toLowerCase().includes(searchTerm.toLowerCase())
    ), [users, searchTerm]);

    const pageCount = Math.ceil(filteredUsers.length / ITEMS_PER_PAGE);
    const paginatedUsers = filteredUsers.slice((currentPage - 1) * ITEMS_PER_PAGE, currentPage * ITEMS_PER_PAGE);

    const handleDelete = async (userToDelete: AdminUser) => {
        if (!user) return;
        const toastId = toast.loading(`Apagando ${userToDelete.email}...`);

        const requestId = doc(collection(db, 'function_requests')).id;
        const responseDocRef = doc(db, 'function_responses', requestId);

        const unsubscribe = onSnapshot(responseDocRef, (docSnap) => {
            if (docSnap.exists()) {
                const response = docSnap.data();
                unsubscribe();
                if (response.result) {
                    toast.success(response.result.message || "Utilizador apagado com sucesso!", { id: toastId });
                    fetchUsers();
                } else {
                    toast.error(`Erro ao apagar: ${response.error}`, { id: toastId });
                }
            }
        });

        try {
            await setDoc(doc(db, 'function_requests', requestId), {
                type: 'DELETE_ADMIN_USER',
                requesterUid: user.uid,
                createdAt: serverTimestamp(),
                payload: { uid: userToDelete.uid, requesterUid: user.uid }
            });
        } catch (error: any) {
            toast.error(`Falha ao solicitar a exclusão: ${error.message}`, { id: toastId });
            unsubscribe();
        }
    };

    if (loading) return <div className="flex justify-center items-center h-full"><Loader2 className="animate-spin" /></div>;
    if (userRole !== 'superAdmin') return <Card><CardHeader><CardTitle>Acesso Negado</CardTitle></CardHeader></Card>;

    return (
        <Card>
            <CardHeader>
                <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4">
                    <div>
                        <CardTitle>Gerir Utilizadores</CardTitle>
                        <CardDescription>Adicione ou remova administradores do painel.</CardDescription>
                    </div>
                    <div className="flex flex-wrap items-center gap-2 w-full sm:w-auto">
                        <div className="relative w-full sm:w-auto flex-grow">
                            <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
                            <Input
                                type="search"
                                placeholder="Pesquisar por email ou ID..."
                                className="pl-8 w-full"
                                value={searchTerm}
                                onChange={(e) => { setSearchTerm(e.target.value); setCurrentPage(1); }}
                            />
                        </div>
                        <SetSuperAdminDialog onUpdate={fetchUsers} /> {/* <-- ADICIONADO */}
                        <AddAdminDialog onUpdate={fetchUsers} />
                    </div>
                </div>
            </CardHeader>
            <CardContent>
                {filteredUsers.length === 0 ? (
                    <EmptyState
                        icon={UserX}
                        title="Nenhum utilizador encontrado"
                        description="Adicione um novo utilizador para começar a gerir."
                    />
                ) : (
                    <Table>
                        <TableHeader><TableRow><TableHead>Email</TableHead><TableHead>Permissão</TableHead><TableHead className="text-right">Ações</TableHead></TableRow></TableHeader>
                        <TableBody>
                            {paginatedUsers.map((u) => (
                                <TableRow key={u.uid}>
                                    <TableCell className="font-medium">{u.email}</TableCell>
                                    <TableCell>{u.superAdmin ? <Badge>Super Admin</Badge> : <Badge variant="secondary">Admin de {u.providerId}</Badge>}</TableCell>
                                    <TableCell className="text-right">
                                        {user?.uid !== u.uid && (
                                            <AlertDialog>
                                                <AlertDialogTrigger asChild><Button variant="destructive" size="sm"><Trash2 className="h-4 w-4" /></Button></AlertDialogTrigger>
                                                <AlertDialogContent>
                                                    <AlertDialogHeader><AlertDialogTitle>Tem a certeza?</AlertDialogTitle><AlertDialogDescription>Esta ação é irreversível.</AlertDialogDescription></AlertDialogHeader>
                                                    <AlertDialogFooter>
                                                        <AlertDialogCancel>Cancelar</AlertDialogCancel>
                                                        <AlertDialogAction onClick={() => handleDelete(u)}>Sim, apagar</AlertDialogAction>
                                                    </AlertDialogFooter>
                                                </AlertDialogContent>
                                            </AlertDialog>
                                        )}
                                    </TableCell>
                                </TableRow>
                            ))}
                        </TableBody>
                    </Table>
                )}
            </CardContent>
            {filteredUsers.length > 0 && (
                <CardFooter className="flex items-center justify-between">
                    <span className="text-sm text-muted-foreground">A exibir {paginatedUsers.length} de {filteredUsers.length} utilizadores.</span>
                    <div className="flex items-center gap-2">
                        <Button variant="outline" size="sm" onClick={() => setCurrentPage(p => Math.max(1, p - 1))} disabled={currentPage === 1}>Anterior</Button>
                        <span className="text-sm">Página {currentPage} de {pageCount > 0 ? pageCount : 1}</span>
                        <Button variant="outline" size="sm" onClick={() => setCurrentPage(p => Math.min(pageCount, p + 1))} disabled={currentPage === pageCount || pageCount === 0}>Próxima</Button>
                    </div>
                </CardFooter>
            )}
        </Card>
    );
}
