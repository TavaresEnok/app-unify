import { useState, useEffect, useMemo } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { toast } from 'sonner';
import { Timestamp } from 'firebase/firestore';
import { Loader2, Activity, Trash2, Search, Download, ExternalLink } from 'lucide-react';
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

// Espelha o que o app grava em provedores/{id}/diagnostic_results
// (DiagnosticReportService.persistResult).
interface DiagnosticResult {
    id: string;
    contractId?: number;
    planName?: string;
    severity?: 'ok' | 'attention' | 'critical';
    headline?: string;
    needsProviderSupport?: boolean;
    findings?: Array<{ title: string; area: string; severity: string }>;
    reportUrl?: string;
    measurements?: {
        speed?: { downloadMbps?: number; uploadMbps?: number; pingMs?: number };
        googlePing?: { latencyMs?: number; lossPercent?: number };
        onu?: { rxPower?: number; status?: string };
        device?: { connectionType?: string };
    };
    createdAt?: Timestamp;
}

const SEVERITY_META: Record<string, { label: string; tone: 'green' | 'amber' | 'red' }> = {
    ok: { label: 'OK', tone: 'green' },
    attention: { label: 'Atenção', tone: 'amber' },
    critical: { label: 'Crítico', tone: 'red' },
};

function formatDate(timestamp?: Timestamp): string {
    if (!timestamp) return '-';
    try {
        return timestamp.toDate().toLocaleString('pt-BR', {
            day: '2-digit', month: '2-digit', year: 'numeric',
            hour: '2-digit', minute: '2-digit',
        });
    } catch {
        return '-';
    }
}

function num(value: number | undefined, digits = 1): string {
    return typeof value === 'number' ? value.toFixed(digits) : '-';
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

    // Métrica de deflexão (§ estudo 4.4): dos diagnósticos feitos, quantos o app
    // resolveu sozinho (problema do cliente) vs quantos apontaram o provedor.
    // É o número que prova a redução de visita técnica.
    const metrics = useMemo(() => {
        const total = results.length;
        const needsProvider = results.filter((r) => r.needsProviderSupport).length;
        const critical = results.filter((r) => r.severity === 'critical').length;
        const selfResolvable = results.filter(
            (r) => r.severity !== 'ok' && !r.needsProviderSupport,
        ).length;
        const deflectionRate = total === 0 ? 0 : Math.round((selfResolvable / total) * 100);
        return { total, needsProvider, critical, selfResolvable, deflectionRate };
    }, [results]);

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

    const filteredResults = results.filter((r) =>
        String(r.contractId ?? '').includes(searchTerm) ||
        (r.planName ?? '').toLowerCase().includes(searchTerm.toLowerCase()) ||
        (r.headline ?? '').toLowerCase().includes(searchTerm.toLowerCase())
    );

    const exportCSV = () => {
        const headers = ['Contrato', 'Plano', 'Data/Hora', 'Severidade', 'Resultado', 'Encaminhamento', 'Download (Mbps)', 'Ping (ms)'];
        const rows = filteredResults.map((r) => [
            r.contractId ?? '',
            r.planName ?? '',
            formatDate(r.createdAt),
            SEVERITY_META[r.severity ?? '']?.label ?? '-',
            (r.headline ?? '').replace(/[,;\n]/g, ' '),
            r.needsProviderSupport ? 'Provedor' : 'Cliente',
            num(r.measurements?.speed?.downloadMbps),
            num(r.measurements?.googlePing?.latencyMs, 0),
        ]);
        const csv = [headers.join(','), ...rows.map((r) => r.join(','))].join('\n');
        const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
        const link = document.createElement('a');
        link.href = URL.createObjectURL(blob);
        link.download = `diagnosticos_${new Date().toISOString().split('T')[0]}.csv`;
        link.click();
        URL.revokeObjectURL(link.href);
        toast.success('CSV exportado com sucesso');
    };

    if (loading) {
        return (
            <div className="flex flex-col justify-center items-center h-full text-center">
                <Loader2 className="animate-spin h-8 w-8 mb-4" />
                <p className="text-lg font-semibold">Carregando diagnósticos...</p>
            </div>
        );
    }

    return (
        <div className="flex flex-col gap-4">
            {results.length > 0 && (
                <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
                    <MetricCard label="Diagnósticos" value={String(metrics.total)} />
                    <MetricCard
                        label="Resolvidos sem visita"
                        value={`${metrics.deflectionRate}%`}
                        hint={`${metrics.selfResolvable} de ${metrics.total} apontaram algo que o cliente resolve`}
                        tone="green"
                    />
                    <MetricCard
                        label="Encaminhados ao provedor"
                        value={String(metrics.needsProvider)}
                        hint="Problema provável de fibra/rede"
                        tone="amber"
                    />
                    <MetricCard
                        label="Críticos"
                        value={String(metrics.critical)}
                        tone="red"
                    />
                </div>
            )}

            <DataTable<DiagnosticResult>
                title="Diagnósticos"
                description={results.length > 0 ? `${results.length} diagnósticos registrados no total.` : 'Nenhum diagnóstico registrado ainda.'}
                actions={(
                    <>
                        <div className="relative flex-grow sm:flex-grow-0 sm:w-64">
                            <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
                            <Input
                                type="search"
                                placeholder="Buscar por contrato, plano ou resultado..."
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
                    { label: "Contrato" },
                    { label: "Data" },
                    { label: "Severidade" },
                    { label: "Resultado" },
                    { label: "↓ Mbps", className: "text-right" },
                    { label: "Ping", className: "text-right" },
                    { label: "Encaminhamento" },
                    { label: "PDF" },
                    { label: "" },
                ]}
                gridTemplate="1fr 1fr .9fr 1.8fr .7fr .6fr 1fr .5fr 48px"
                rows={filteredResults}
                getRowKey={(result) => result.id}
                minWidth="980px"
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
                    <div className="grid items-center gap-x-3 border-b border-[#F2F4F7] px-[18px] py-[11px] transition-colors hover:bg-[#F8FAFC]" style={{ gridTemplateColumns: "1fr 1fr .9fr 1.8fr .7fr .6fr 1fr .5fr 48px" }}>
                        <span className="min-w-0">
                            <span className="block truncate text-[13px] font-semibold text-[#1A2233]">{result.contractId ?? '—'}</span>
                            <span className="block truncate text-[11.5px] text-[#98A1B1]">{result.planName ?? '-'}</span>
                        </span>
                        <span className="text-[12px] text-[#687181]">{formatDate(result.createdAt)}</span>
                        <StatusBadge
                            status={SEVERITY_META[result.severity ?? '']?.label ?? '-'}
                            tone={SEVERITY_META[result.severity ?? '']?.tone ?? 'gray'}
                        />
                        <span className="truncate text-[12.5px] text-[#4A5364]" title={result.headline}>{result.headline ?? '-'}</span>
                        <span className="text-right font-mono text-[12px] text-[#4A5364]">{num(result.measurements?.speed?.downloadMbps)}</span>
                        <span className="text-right font-mono text-[12px] text-[#4A5364]">{num(result.measurements?.googlePing?.latencyMs, 0)}ms</span>
                        <StatusBadge
                            status={result.needsProviderSupport ? 'Provedor' : 'Cliente'}
                            tone={result.needsProviderSupport ? 'amber' : 'gray'}
                        />
                        <span>
                            {result.reportUrl ? (
                                <a href={result.reportUrl} target="_blank" rel="noopener noreferrer" className="text-primary hover:underline" title="Abrir relatório PDF">
                                    <ExternalLink className="h-4 w-4" />
                                </a>
                            ) : <span className="text-[#98A1B1]">—</span>}
                        </span>
                        <div className="flex justify-end">
                            <AlertDialog open={deleteId === result.id} onOpenChange={(open) => !open && setDeleteId(null)}>
                                <AlertDialogTrigger asChild>
                                    <Button variant="ghost" size="icon" className="h-8 w-8 text-destructive hover:text-destructive" onClick={() => setDeleteId(result.id)}>
                                        <Trash2 className="h-4 w-4" />
                                    </Button>
                                </AlertDialogTrigger>
                                <AlertDialogContent>
                                    <AlertDialogHeader>
                                        <AlertDialogTitle>Excluir Diagnóstico?</AlertDialogTitle>
                                        <AlertDialogDescription>
                                            Esta ação não pode ser desfeita. O registro do diagnóstico do contrato {result.contractId ?? '—'} será permanentemente excluído.
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
        </div>
    );
}

function MetricCard({ label, value, hint, tone = 'default' }: {
    label: string;
    value: string;
    hint?: string;
    tone?: 'default' | 'green' | 'amber' | 'red';
}) {
    const toneColor = {
        default: 'text-[#1A2233]',
        green: 'text-emerald-600',
        amber: 'text-amber-600',
        red: 'text-red-600',
    }[tone];
    return (
        <div className="rounded-xl border border-[#EEF0F4] bg-white p-4">
            <div className="text-[12px] text-[#98A1B1]">{label}</div>
            <div className={`mt-1 text-[24px] font-bold ${toneColor}`}>{value}</div>
            {hint && <div className="mt-1 text-[11px] text-[#98A1B1]">{hint}</div>}
        </div>
    );
}
