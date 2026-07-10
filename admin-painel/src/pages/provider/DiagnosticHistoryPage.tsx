import { useState, useEffect } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { toast } from 'sonner';
import { Timestamp } from 'firebase/firestore';
import { Loader2, Activity, Trash2, Search, Download } from 'lucide-react';
import EmptyState from '@/components/EmptyState';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import DataTable from '@/components/DataTable';
import StatusBadge from '@/components/StatusBadge';
import {
    AlertDialog,
    AlertDialogAction,
    AlertDialogCancel,
    AlertDialogContent,
    AlertDialogDescription,
    AlertDialogFooter,
    AlertDialogHeader,
    AlertDialogTitle,
    AlertDialogTrigger,
} from "@/components/ui/alert-dialog";
import { deleteDiagnostic, subscribeDiagnostics } from '@/features/diagnostics/diagnosticService';

interface DiagnosticResult {
    id: string;
    clientId: string;
    clientName: string;
    clientPlan: string;
    timestamp: string;
    downloadSpeed: number;
    uploadSpeed: number;
    ping: number;
    jitter: number;
    packetLoss: number;
    healthScore: number;
    testMode: string;
    connectionType: string;
    deviceInfo?: {
        model: string;
        os: string;
        appVersion: string;
    };
    additionalData?: {
        wifiRssi?: string;
        onuStatus?: string;
        deviceCount?: string;
    };
    createdAt?: Timestamp;
}

function getScoreTone(score: number) {
    if (score >= 80) return 'green';
    if (score >= 60) return 'amber';
    return 'red';
}

function formatDate(timestamp: string | Timestamp): string {
    try {
        const date = timestamp instanceof Timestamp
            ? timestamp.toDate()
            : new Date(timestamp);
        return date.toLocaleString('pt-BR', {
            day: '2-digit',
            month: '2-digit',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
    } catch {
        return '-';
    }
}

export default function DiagnosticHistoryPage() {
    const { providerId } = useAuth();
    const [results, setResults] = useState<DiagnosticResult[]>([]);
    const [loading, setLoading] = useState(true);
    const [searchTerm, setSearchTerm] = useState('');
    const [deleteId, setDeleteId] = useState<string | null>(null);

    useEffect(() => {
        if (!providerId) return;

        const unsubscribe = subscribeDiagnostics<DiagnosticResult>(providerId, (data) => {
            setResults(data);
            setLoading(false);
        }, (error) => {
            console.error('Error fetching diagnostics:', error);
            toast.error('Erro ao carregar diagnósticos');
            setLoading(false);
        });

        return () => unsubscribe();
    }, [providerId]);

    const handleDelete = async (id: string) => {
        if (!providerId) return;
        try {
            await deleteDiagnostic(providerId, id);
            toast.success('Registro excluído com sucesso');
        } catch (error) {
            console.error('Error deleting:', error);
            toast.error('Erro ao excluir registro');
        }
        setDeleteId(null);
    };

    const exportCSV = () => {
        const headers = ['Cliente', 'Plano', 'Data/Hora', 'Download (Mbps)', 'Upload (Mbps)', 'Ping (ms)', 'Score', 'Modo', 'Conexão'];
        const rows = filteredResults.map(r => [
            r.clientName,
            r.clientPlan,
            formatDate(r.timestamp || r.createdAt!),
            r.downloadSpeed.toFixed(1),
            r.uploadSpeed.toFixed(1),
            r.ping,
            r.healthScore,
            r.testMode,
            r.connectionType
        ]);

        const csv = [headers.join(','), ...rows.map(r => r.join(','))].join('\n');
        const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
        const link = document.createElement('a');
        link.href = URL.createObjectURL(blob);
        link.download = `diagnosticos_${new Date().toISOString().split('T')[0]}.csv`;
        link.click();
        toast.success('CSV exportado com sucesso');
    };

    const filteredResults = results.filter(r =>
        r.clientName?.toLowerCase().includes(searchTerm.toLowerCase()) ||
        r.clientId?.toLowerCase().includes(searchTerm.toLowerCase())
    );

    if (loading) {
        return (
            <div className="flex flex-col justify-center items-center h-full text-center">
                <Loader2 className="animate-spin h-8 w-8 mb-4" />
                <p className="text-lg font-semibold">Carregando diagnósticos...</p>
            </div>
        );
    }

    return (
        <DataTable<DiagnosticResult>
            title="Diagnósticos"
            description={results.length > 0 ? `${results.length} testes registrados no total.` : "Nenhum diagnóstico registrado ainda."}
            actions={(
                <>
                        <div className="relative flex-grow sm:flex-grow-0 sm:w-64">
                            <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
                            <Input
                                type="search"
                                placeholder="Buscar por cliente..."
                                className="pl-8 w-full"
                                value={searchTerm}
                                onChange={(e) => setSearchTerm(e.target.value)}
                            />
                        </div>
                        <Button onClick={exportCSV} variant="outline" disabled={results.length === 0}>
                            <Download className="mr-2 h-4 w-4" />
                            Exportar CSV
                        </Button>
                </>
            )}
            columns={[
                { label: "Cliente" },
                { label: "Data" },
                { label: "↓ Mbps", className: "text-right" },
                { label: "↑ Mbps", className: "text-right" },
                { label: "Ping", className: "text-right" },
                { label: "Score" },
                { label: "Modo" },
                { label: "Conexão" },
                { label: "" },
            ]}
            gridTemplate="1.7fr 1fr .7fr .7fr .6fr .7fr .8fr .8fr 48px"
            rows={filteredResults}
            getRowKey={(result) => result.id}
            minWidth="940px"
            empty={(
                    <EmptyState
                        icon={Activity}
                        title={searchTerm ? "Nenhum resultado para sua busca" : "Nenhum Diagnóstico Registrado"}
                        description={searchTerm
                            ? `Não foram encontrados diagnósticos para "${searchTerm}".`
                            : "Os diagnósticos feitos pelos clientes no app aparecerão aqui automaticamente."}
                    />
            )}
            renderRow={(result) => (
                            <div className="grid items-center gap-x-3 border-b border-[#F2F4F7] px-[18px] py-[11px] transition-colors hover:bg-[#F8FAFC]" style={{ gridTemplateColumns: "1.7fr 1fr .7fr .7fr .6fr .7fr .8fr .8fr 48px" }}>
                                <span className="min-w-0">
                                    <span className="block truncate text-[13px] font-semibold text-[#1A2233]">{result.clientName}</span>
                                    <span className="block truncate text-[11.5px] text-[#98A1B1]">{result.clientPlan}</span>
                                </span>
                                <span className="text-[12px] text-[#687181]">
                                            {formatDate(result.timestamp || result.createdAt!)}
                                </span>
                                <span className="text-right font-mono text-[12px] text-[#4A5364]">
                                            {result.downloadSpeed.toFixed(1)}
                                </span>
                                <span className="text-right font-mono text-[12px] text-[#4A5364]">
                                            {result.uploadSpeed.toFixed(1)}
                                </span>
                                <span className="text-right font-mono text-[12px] text-[#4A5364]">
                                            {result.ping}ms
                                </span>
                                <StatusBadge status={String(result.healthScore)} tone={getScoreTone(result.healthScore)} />
                                <StatusBadge status={result.testMode} tone="gray" />
                                <span className="capitalize text-[12.5px] text-[#4A5364]">{result.connectionType}</span>
                                <div className="flex justify-end">
                                            <AlertDialog open={deleteId === result.id} onOpenChange={(open) => !open && setDeleteId(null)}>
                                                <AlertDialogTrigger asChild>
                                                    <Button
                                                        variant="ghost"
                                                        size="icon"
                                                        className="h-8 w-8 text-destructive hover:text-destructive"
                                                        onClick={() => setDeleteId(result.id)}
                                                    >
                                                        <Trash2 className="h-4 w-4" />
                                                    </Button>
                                                </AlertDialogTrigger>
                                                <AlertDialogContent>
                                                    <AlertDialogHeader>
                                                        <AlertDialogTitle>Excluir Diagnóstico?</AlertDialogTitle>
                                                        <AlertDialogDescription>
                                                            Esta ação não pode ser desfeita. O registro do diagnóstico de {result.clientName} será permanentemente excluído.
                                                        </AlertDialogDescription>
                                                    </AlertDialogHeader>
                                                    <AlertDialogFooter>
                                                        <AlertDialogCancel>Cancelar</AlertDialogCancel>
                                                        <AlertDialogAction onClick={() => handleDelete(result.id)} className="bg-destructive text-destructive-foreground hover:bg-destructive/90">
                                                            Excluir
                                                        </AlertDialogAction>
                                                    </AlertDialogFooter>
                                                </AlertDialogContent>
                                            </AlertDialog>
                                </div>
                            </div>
            )}
            footer={filteredResults.length > 0 && (
                <div className="text-[12px] text-[#98A1B1]">
                    Exibindo {filteredResults.length} de {results.length} registros
                </div>
            )}
        />
    );
}
