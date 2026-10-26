// admin-painel/src/pages/UsersPage.tsx - VERSÃO FINAL MIGRADA
import { useState, useEffect, useMemo, useCallback } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { Card, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Loader2, Trash2, UserX, Search } from 'lucide-react';
import AddAdminDialog from '@/components/AddAdminDialog.tsx';
import SetSuperAdminDialog from '@/components/SetSuperAdminDialog.tsx'; // <-- ADICIONADO
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle, AlertDialogTrigger } from "@/components/ui/alert-dialog";
import EmptyState from '@/components/EmptyState.tsx';
import DataTable from '@/components/DataTable';
import StatusBadge from '@/components/StatusBadge';
import { useApi } from '@/hooks/useApi';

interface AdminUser {
    uid: string;
    email?: string;
    superAdmin: boolean;
    providerId?: string;
}

const ITEMS_PER_PAGE = 10;

export default function UsersPage() {
    const { user, userRole } = useAuth();
    const { callFunction } = useApi();
    const [users, setUsers] = useState<AdminUser[]>([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [currentPage, setCurrentPage] = useState(1);

    const fetchUsers = useCallback(async () => {
        if (userRole !== 'superAdmin' || !user) {
            setLoading(false);
            return;
        }
        setLoading(true);
        try {
            const result = await callFunction('LIST_ADMIN_USERS', {});
            setUsers(result);
        } catch (error) {
            console.error("Falha ao carregar utilizadores", error);
        } finally {
            setLoading(false);
        }
    }, [userRole, user, callFunction]);

    useEffect(() => {
        void fetchUsers();
    }, [fetchUsers]);

    const filteredUsers = useMemo(() => users.filter(u =>
        u.email?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        u.providerId?.toLowerCase().includes(searchTerm.toLowerCase())
    ), [users, searchTerm]);

    const pageCount = Math.ceil(filteredUsers.length / ITEMS_PER_PAGE);
    const paginatedUsers = filteredUsers.slice((currentPage - 1) * ITEMS_PER_PAGE, currentPage * ITEMS_PER_PAGE);

    const handleDelete = async (userToDelete: AdminUser) => {
        if (!user) return;
        try {
            await callFunction('DELETE_ADMIN_USER', { uid: userToDelete.uid });
            await fetchUsers();
        } catch (error) {
            console.error("Falha ao apagar utilizador", error);
        }
    };

    if (loading) return <div className="flex justify-center items-center h-full"><Loader2 className="animate-spin" /></div>;
    if (userRole !== 'superAdmin') return <Card><CardHeader><CardTitle>Acesso Negado</CardTitle></CardHeader></Card>;

    return (
        <DataTable<AdminUser>
            title="Utilizadores"
            description="Adicione ou remova administradores do painel."
            actions={(
                <>
                    <div className="relative w-full flex-grow sm:w-[260px] sm:flex-grow-0">
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
                </>
            )}
            columns={[
                { label: "Utilizador" },
                { label: "Permissão" },
                { label: "Provedor" },
                { label: "Último acesso" },
                { label: "Status" },
                { label: "" },
            ]}
            gridTemplate="2fr 1.1fr 1fr .9fr .8fr 52px"
            rows={paginatedUsers}
            getRowKey={(adminUser) => adminUser.uid}
            minWidth="880px"
            empty={(
                    <EmptyState
                        icon={UserX}
                        title="Nenhum utilizador encontrado"
                        description="Adicione um novo utilizador para começar a gerir."
                    />
            )}
            renderRow={(u) => (
                            <div className="grid items-center gap-x-3 border-b border-[#F2F4F7] px-[18px] py-[11px] transition-colors hover:bg-[#F8FAFC]" style={{ gridTemplateColumns: "2fr 1.1fr 1fr .9fr .8fr 52px" }}>
                                <span className="min-w-0">
                                    <span className="block truncate text-[13px] font-semibold text-[#1A2233]">{u.email}</span>
                                    <span className="block truncate font-mono text-[10.5px] text-[#98A1B1]">{u.uid}</span>
                                </span>
                                <StatusBadge status={u.superAdmin ? "Super Admin" : "Admin"} tone={u.superAdmin ? "blue" : "gray"} />
                                <span className="truncate text-[12.5px] text-[#4A5364]">{u.superAdmin ? "Plataforma" : u.providerId || "-"}</span>
                                <span className="font-mono text-[11.5px] text-[#98A1B1]">-</span>
                                <StatusBadge status="Ativo" />
                                <div className="flex justify-end">
                                        {user?.uid !== u.uid && (
                                            <AlertDialog>
                                            <AlertDialogTrigger asChild><Button variant="destructive" size="icon"><Trash2 className="h-4 w-4" /></Button></AlertDialogTrigger>
                                                <AlertDialogContent>
                                                    <AlertDialogHeader><AlertDialogTitle>Tem a certeza?</AlertDialogTitle><AlertDialogDescription>Esta ação é irreversível.</AlertDialogDescription></AlertDialogHeader>
                                                    <AlertDialogFooter>
                                                        <AlertDialogCancel>Cancelar</AlertDialogCancel>
                                                        <AlertDialogAction onClick={() => handleDelete(u)}>Sim, apagar</AlertDialogAction>
                                                    </AlertDialogFooter>
                                                </AlertDialogContent>
                                            </AlertDialog>
                                        )}
                                </div>
                            </div>
            )}
            footer={filteredUsers.length > 0 && (
                <div className="flex items-center justify-between">
                    <span className="text-[12px] text-[#98A1B1]">Exibindo {paginatedUsers.length} de {filteredUsers.length} utilizadores</span>
                    <div className="flex items-center gap-2">
                        <Button variant="outline" size="sm" onClick={() => setCurrentPage(p => Math.max(1, p - 1))} disabled={currentPage === 1}>Anterior</Button>
                        <Button variant="outline" size="sm" onClick={() => setCurrentPage(p => Math.min(pageCount, p + 1))} disabled={currentPage === pageCount || pageCount === 0}>Próxima</Button>
                    </div>
                </div>
            )}
        />
    );
}
