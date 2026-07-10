// admin-painel/src/pages/provider-settings/BackupSettings.tsx - VERSÃO ATUALIZADA
import { useState, useEffect, useContext, useCallback } from 'react';
import { Button } from '@/components/ui/button';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle, AlertDialogTrigger } from "@/components/ui/alert-dialog";
import { Loader2, HardDriveUpload, History, Trash2, DatabaseZap } from 'lucide-react';
import { toast } from 'sonner';
import { SettingsContext } from '@/contexts/SettingsContext.tsx';
import { useAuth } from '@/contexts/AuthContext';
import { db } from '@/firebase/config';
import { doc, setDoc, onSnapshot, serverTimestamp, collection } from "firebase/firestore";
import EmptyState from '@/components/EmptyState.tsx';
import { SettingsPage, SettingsSection } from '@/components/settings/SettingsPage';

interface Backup {
    id: string;
    createdAt: string;
}

// Função auxiliar para criar requisições e aguardar respostas
const makeRequest = (userUid: string, type: string, payload: object): Promise<any> => {
    return new Promise((resolve, reject) => {
        const requestId = doc(collection(db, 'function_requests')).id;
        const responseDocRef = doc(db, 'function_responses', requestId);

        const unsubscribe = onSnapshot(responseDocRef, (docSnap) => {
            if (docSnap.exists()) {
                const response = docSnap.data();
                unsubscribe();
                if (response.result) {
                    resolve(response.result);
                } else {
                    reject(new Error(response.error || "Ocorreu um erro desconhecido na função."));
                }
            }
        });

        setDoc(doc(db, 'function_requests', requestId), {
            type,
            requesterUid: userUid,
            createdAt: serverTimestamp(),
            payload,
        }).catch(err => {
            unsubscribe();
            reject(err);
        });
    });
};

export default function BackupSettings() {
    const context = useContext(SettingsContext);
    const { user } = useAuth();
    const [backups, setBackups] = useState<Backup[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [isActioning, setIsActioning] = useState<string | boolean>(false); // string para ID, boolean para geral
    const providerId = context?.providerId;

    const fetchBackups = useCallback(async () => {
        if (!providerId || !user) return;
        setIsLoading(true);
        try {
            const result = await makeRequest(user.uid, 'LIST_PROVIDER_BACKUPS', { providerId, requesterUid: user.uid });
            setBackups(result.backups || []);
        } catch (error: any) {
            toast.error(`Erro ao listar backups: ${error.message}`);
            setBackups([]); // Limpa em caso de erro
        } finally {
            setIsLoading(false);
        }
    }, [providerId, user]);

    useEffect(() => {
        if(providerId) {
            fetchBackups();
        } else {
            setIsLoading(false);
        }
    }, [providerId, fetchBackups]);

    const handleCreateBackup = async () => {
        if (!providerId || !user) return;
        setIsActioning(true);
        const toastId = toast.loading("A criar novo backup...");
        try {
            await makeRequest(user.uid, 'BACKUP_PROVIDER_CONFIG', { providerId, requesterUid: user.uid });
            toast.success("Backup criado com sucesso!", { id: toastId });
            fetchBackups();
        } catch (error: any) {
            toast.error(`Erro ao criar backup: ${error.message}`, { id: toastId });
        } finally {
            setIsActioning(false);
        }
    };

    const handleRestore = async (backupId: string) => {
        if (!providerId || !user) return;
        setIsActioning(backupId);
        const toastId = toast.loading(`A restaurar backup...`);
        try {
            await makeRequest(user.uid, 'RESTORE_PROVIDER_CONFIG', { providerId, backupId, requesterUid: user.uid });
            toast.success("Configurações restauradas! A página será recarregada.", { id: toastId });
            setTimeout(() => window.location.reload(), 2000);
        } catch (error: any) {
            toast.error(`Erro ao restaurar: ${error.message}`, { id: toastId });
        } finally {
            setIsActioning(false);
        }
    };
    
    const handleDelete = async (backupId: string) => {
        if (!providerId || !user) return;
        setIsActioning(backupId);
        const toastId = toast.loading(`Apagando backup...`);
        try {
            await makeRequest(user.uid, 'DELETE_PROVIDER_BACKUP', { providerId, backupId, requesterUid: user.uid });
            toast.success("Backup apagado.", { id: toastId });
            fetchBackups(); // Recarrega a lista
        } catch (error: any) {
            toast.error(`Erro ao apagar: ${error.message}`, { id: toastId });
        } finally {
            setIsActioning(false);
        }
    };

    return (
        <SettingsPage
            title="Backup e Restauração"
            description="Crie cópias de segurança das configurações de personalização ou restaure uma versão anterior."
            icon={DatabaseZap}
            actions={(
                    <Button onClick={handleCreateBackup} disabled={!!isActioning || isLoading}>
                        {isActioning === true ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <HardDriveUpload className="mr-2 h-4 w-4" />}
                        Criar Novo Backup
                    </Button>
            )}
        >
            <SettingsSection title="Histórico de backups" description="Versões disponíveis para restauração.">
                {isLoading ? (
                    <div className="flex justify-center items-center py-10"><Loader2 className="h-8 w-8 animate-spin" /></div>
                ) : backups.length === 0 ? (
                    <EmptyState 
                        icon={DatabaseZap}
                        title="Nenhum backup encontrado"
                        description="Crie um novo backup para guardar uma cópia das configurações atuais."
                    />
                ) : (
                    <Table>
                        <TableHeader><TableRow><TableHead>Data do Backup</TableHead><TableHead>ID do Backup</TableHead><TableHead className="text-right">Ações</TableHead></TableRow></TableHeader>
                        <TableBody>
                            {backups.map(backup => (
                                <TableRow key={backup.id}>
                                    <TableCell>{new Date(backup.createdAt).toLocaleString('pt-BR')}</TableCell>
                                    <TableCell className="font-mono">{backup.id}</TableCell>
                                    <TableCell className="text-right space-x-2">
                                        <AlertDialog>
                                            <AlertDialogTrigger asChild><Button variant="outline" size="sm" disabled={!!isActioning}><History className="mr-2 h-4 w-4" />Restaurar</Button></AlertDialogTrigger>
                                            <AlertDialogContent>
                                                <AlertDialogHeader><AlertDialogTitle>Restaurar este backup?</AlertDialogTitle><AlertDialogDescription>Todas as configurações de personalização atuais serão substituídas pelas do backup de {new Date(backup.createdAt).toLocaleString('pt-BR')}. Esta ação não pode ser desfeita.</AlertDialogDescription></AlertDialogHeader>
                                                <AlertDialogFooter><AlertDialogCancel>Cancelar</AlertDialogCancel><AlertDialogAction onClick={() => handleRestore(backup.id)}>Sim, restaurar</AlertDialogAction></AlertDialogFooter>
                                            </AlertDialogContent>
                                        </AlertDialog>
                                        <AlertDialog>
                                            <AlertDialogTrigger asChild><Button variant="destructive" size="sm" disabled={!!isActioning}><Trash2 className="h-4 w-4" /></Button></AlertDialogTrigger>
                                            <AlertDialogContent>
                                                <AlertDialogHeader><AlertDialogTitle>Apagar este backup?</AlertDialogTitle><AlertDialogDescription>Esta ação é permanente e não pode ser desfeita.</AlertDialogDescription></AlertDialogHeader>
                                                <AlertDialogFooter><AlertDialogCancel>Cancelar</AlertDialogCancel><AlertDialogAction onClick={() => handleDelete(backup.id)}>Sim, apagar</AlertDialogAction></AlertDialogFooter>
                                            </AlertDialogContent>
                                        </AlertDialog>
                                    </TableCell>
                                </TableRow>
                            ))}
                        </TableBody>
                    </Table>
                )}
            </SettingsSection>
        </SettingsPage>
    );
}
