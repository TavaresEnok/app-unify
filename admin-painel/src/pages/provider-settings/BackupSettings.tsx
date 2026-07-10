// admin-painel/src/pages/provider-settings/BackupSettings.tsx - VERSÃO ATUALIZADA
import { useState, useEffect, useContext, useCallback } from 'react';
import { Button } from '@/components/ui/button';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle, AlertDialogTrigger } from "@/components/ui/alert-dialog";
import { Loader2, HardDriveUpload, History, Trash2, DatabaseZap } from 'lucide-react';
import { toast } from 'sonner';
import { SettingsContext } from '@/contexts/SettingsContext.tsx';
import EmptyState from '@/components/EmptyState.tsx';
import { SettingsPage, SettingsSection } from '@/components/settings/SettingsPage';
import { useApi } from '@/hooks/useApi';
import { getErrorMessage } from '@/shared/errors';

interface Backup {
    id: string;
    createdAt: string;
}

export default function BackupSettings() {
    const context = useContext(SettingsContext);
    const { callFunction } = useApi();
    const [backups, setBackups] = useState<Backup[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [isActioning, setIsActioning] = useState<string | boolean>(false); // string para ID, boolean para geral
    const providerId = context?.providerId;

    const fetchBackups = useCallback(async () => {
        if (!providerId) return;
        setIsLoading(true);
        try {
            const result = await callFunction('LIST_PROVIDER_BACKUPS', { providerId });
            setBackups(result as unknown as Backup[]);
        } catch (error) {
            toast.error(`Erro ao listar backups: ${getErrorMessage(error)}`);
            setBackups([]); // Limpa em caso de erro
        } finally {
            setIsLoading(false);
        }
    }, [providerId, callFunction]);

    useEffect(() => {
        if(providerId) {
            fetchBackups();
        } else {
            setIsLoading(false);
        }
    }, [providerId, fetchBackups]);

    const handleCreateBackup = async () => {
        if (!providerId) return;
        setIsActioning(true);
        const toastId = toast.loading("A criar novo backup...");
        try {
            await callFunction('BACKUP_PROVIDER_CONFIG', { providerId });
            toast.success("Backup criado com sucesso!", { id: toastId });
            fetchBackups();
        } catch (error) {
            toast.error(`Erro ao criar backup: ${getErrorMessage(error)}`, { id: toastId });
        } finally {
            setIsActioning(false);
        }
    };

    const handleRestore = async (backupId: string) => {
        if (!providerId) return;
        setIsActioning(backupId);
        const toastId = toast.loading(`A restaurar backup...`);
        try {
            await callFunction('RESTORE_PROVIDER_CONFIG', { providerId, backupId });
            toast.success("Configurações restauradas! A página será recarregada.", { id: toastId });
            setTimeout(() => window.location.reload(), 2000);
        } catch (error) {
            toast.error(`Erro ao restaurar: ${getErrorMessage(error)}`, { id: toastId });
        } finally {
            setIsActioning(false);
        }
    };
    
    const handleDelete = async (backupId: string) => {
        if (!providerId) return;
        setIsActioning(backupId);
        const toastId = toast.loading(`Apagando backup...`);
        try {
            await callFunction('DELETE_PROVIDER_BACKUP', { providerId, backupId });
            toast.success("Backup apagado.", { id: toastId });
            fetchBackups(); // Recarrega a lista
        } catch (error) {
            toast.error(`Erro ao apagar: ${getErrorMessage(error)}`, { id: toastId });
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
