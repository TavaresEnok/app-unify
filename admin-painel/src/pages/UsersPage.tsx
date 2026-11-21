// admin-painel/src/pages/UsersPage.tsx - VERSÃO FINAL MIGRADA
import { useState, useMemo } from 'react';
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
import { usePanelPage } from '@/hooks/usePanelPage';
import { PageControls } from '@/components/PageControls';

interface AdminUser {
    uid: string;
    email?: string;
    superAdmin: boolean;
    providerId?: string;
}



export default function UsersPage() {
    const { user, userRole } = useAuth();
    const { callFunction } = useApi();
    const page = usePanelPage<AdminUser>('/admin/users/page');
    const { data: users, loading, reload: fetchUsers } = page;
    const [searchTerm, setSearchTerm] = useState('');

    const filteredUsers = useMemo(() => users.filter(u =>
        u.email?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        u.providerId?.toLowerCase().includes(searchTerm.toLowerCase())
    ), [users, searchTerm]);

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
    if (page.error) return <div role="alert">{page.error}<Button onClick={fetchUsers}>Tentar novamente</Button></div>;
    if (userRole !== 'superAdmin') return <Card><CardHeader><CardTitle>Acesso Negado</CardTitle></CardHeader></Card>;

    return (
        <DataTable<AdminUser>
            title="Equipe"
            description="Adicione ou remova administradores do painel."
            actions={(
                <>
                    <div className="relative w-full flex-grow sm:w-[260px] sm:flex-grow-0">
                            <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
                            <Input
                                type="search"
                                placeholder="Buscar nesta página..."
                                className="pl-8 w-full"
                                value={searchTerm}
                                onChange={(e) => { setSearchTerm(e.target.value); }}
                            />
                        </div>
                        <SetSuperAdminDialog onUpdate={fetchUsers} /> {/* <-- ADICIONADO */}
                        <AddAdminDialog onUpdate={fetchUsers} />
                </>
            )}
            columns={[
                { label: "Usuário" },
                { label: "Permissão" },
                { label: "Provedor" },
                { label: "Último acesso" },
                { label: "Status" },
                { label: "" },
            ]}
            gridTemplate="2fr 1.1fr 1fr .9fr .8fr 52px"
            rows={filteredUsers}
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
            footer={<PageControls page={page} />}
        />
    );
}
