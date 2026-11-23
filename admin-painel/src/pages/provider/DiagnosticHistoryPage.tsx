import { useState, useEffect, useMemo, useCallback } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { toast } from 'sonner';
import { Loader2, Activity, Trash2, Search, Download, RefreshCw } from 'lucide-react';
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
import {
    deleteProviderDiagnostic,
    fetchProviderDiagnostics,
    type DiagnosticResultItem,
} from '@/shared/api/diagnostics';

const VERDICT_META: Record<string, { label: string; tone: 'green' | 'amber' | 'red' | 'gray' }> = {
    healthy: { label: 'OK', tone: 'green' },
    ok: { label: 'OK', tone: 'green' },
    degraded: { label: 'Atenção', tone: 'amber' },
    attention: { label: 'Atenção', tone: 'amber' },
    critical: { label: 'Crítico', tone: 'red' },
    unknown: { label: 'Parcial', tone: 'gray' },
};

function formatDate(iso?: string): string {
    if (!iso) return '-';
    try {
        const d = new Date(iso);
        if (Number.isNaN(d.getTime())) return '-';
        return d.toLocaleString('pt-BR', {
            day: '2-digit', month: '2-digit', year: 'numeric',
            hour: '2-digit', minute: '2-digit',
        });
    } catch {
        return '-';
    }
}

function num(value: unknown, digits = 1): string {
    return typeof value === 'number' && Number.isFinite(value) ? value.toFixed(digits) : '-';
}

function needsProvider(item: DiagnosticResultItem): boolean {
    if (typeof item.summary?.needsProviderSupport === 'boolean') {
        return item.summary.needsProviderSupport;
    }
    return item.verdict === 'critical';
}

export default function DiagnosticHistoryPage() {
    const { providerId, user } = useAuth();
    const [results, setResults] = useState<DiagnosticResultItem[]>([]);
    const [loading, setLoading] = useState(true);
    const [refreshing, setRefreshing] = useState(false);
    const [searchTerm, setSearchTerm] = useState('');
    const [deleteId, setDeleteId] = useState<string | null>(null);

    const load = useCallback(async (isRefresh = false) => {
        if (!providerId || !user) return;
        if (isRefresh) setRefreshing(true);
        else setLoading(true);
        try {
            const data = await fetchProviderDiagnostics(providerId);
            setResults(data);
        } catch (error) {
            console.error('Error fetching diagnostics:', error);
            toast.error('Erro ao carregar diagnósticos');
        } finally {
            setLoading(false);
            setRefreshing(false);
        }
    }, [providerId, user]);

    useEffect(() => {
        setResults([]);
        void load(false);
    }, [load]);

    // Classificação do diagnóstico; não comprova resolução nem visita evitada.
    const metrics = useMemo(() => {
        const total = results.length;
        const needsProviderCount = results.filter(needsProvider).length;
        const critical = results.filter((r) => r.verdict === 'critical').length;
        const selfResolvable = results.filter(
            (r) => r.verdict !== 'healthy' && r.verdict !== 'ok' && !needsProvider(r),
        ).length;
        const deflectionRate = total === 0 ? 0 : Math.round((selfResolvable / total) * 100);
        return { total, needsProvider: needsProviderCount, critical, selfResolvable, deflectionRate };
    }, [results]);

    const handleDelete = async (id: string) => {
        if (!providerId) return;
        try {
            await deleteProviderDiagnostic(providerId, id);
            setResults((prev) => prev.filter((item) => item.id !== id));
            toast.success('Registro excluído com sucesso');
        } catch (error) {
            console.error('Error deleting:', error);
            toast.error('Erro ao excluir registro');
        }
        setDeleteId(null);
    };

    const q = searchTerm.trim().toLowerCase();
    const filteredResults = q
        ? results.filter((r) =>
            r.contratoId.toLowerCase().includes(q) ||
            r.clientName.toLowerCase().includes(q) ||
            r.cpfCnpj.includes(q.replace(/\D/g, '') || q) ||
            r.planName.toLowerCase().includes(q) ||
            r.verdictHeadline.toLowerCase().includes(q) ||
            r.oltName.toLowerCase().includes(q) ||
            r.bairro.toLowerCase().includes(q),
        )
        : results;

    const exportCSV = () => {
        const headers = ['Contrato', 'Cliente', 'Plano', 'OLT', 'Bairro', 'Data/Hora', 'Severidade', 'Resultado', 'Encaminhamento', 'Download (Mbps)', 'Ping (ms)', 'Sinal ONU (dBm)'];
        const rows = filteredResults.map((r) => [
            r.contratoId || '',
            r.clientName.replace(/[,;\n]/g, ' '),
            r.planName.replace(/[,;\n]/g, ' '),
            r.oltName.replace(/[,;\n]/g, ' '),
            r.bairro.replace(/[,;\n]/g, ' '),
            formatDate(r.createdAt),
            VERDICT_META[r.verdict]?.label ?? '-',
            r.verdictHeadline.replace(/[,;\n]/g, ' '),
            needsProvider(r) ? 'Provedor' : 'Cliente',
            num(r.summary?.downloadMbps),
            num(r.summary?.pingMs, 0),
            num(r.summary?.onuRxDbm, 1),
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
                        label="Orientação ao assinante"
                        value={`${metrics.deflectionRate}%`}
                        hint={`${metrics.selfResolvable} de ${metrics.total} indicaram orientação ao assinante`}
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

            <DataTable<DiagnosticResultItem>
                title="Diagnósticos"
                description={results.length > 0 ? `${results.length} diagnósticos registrados no PostgreSQL.` : 'Nenhum diagnóstico registrado ainda.'}
                actions={(
                    <>
                        <div className="relative flex-grow sm:flex-grow-0 sm:w-72">
                            <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
                            <Input
                                type="search"
                                placeholder="Buscar por contrato, cliente, OLT, bairro..."
                                className="pl-8 w-full"
                                value={searchTerm}
                                onChange={(e) => setSearchTerm(e.target.value)}
                            />
                        </div>
                        <Button onClick={() => void load(true)} variant="outline" disabled={refreshing}>
                            <RefreshCw className={`mr-2 h-4 w-4 ${refreshing ? 'animate-spin' : ''}`} />
                            Atualizar
                        </Button>
                        <Button onClick={exportCSV} variant="outline" disabled={results.length === 0}>
                            <Download className="mr-2 h-4 w-4" />
                            Exportar CSV
                        </Button>
                    </>
                )}
                columns={[
                    { label: "Contrato / Cliente" },
                    { label: "OLT / Bairro" },
                    { label: "Data" },
                    { label: "Severidade" },
                    { label: "Resultado" },
                    { label: "↓ Mbps", className: "text-right" },
                    { label: "Ping", className: "text-right" },
                    { label: "Encaminhamento" },
                    { label: "" },
                ]}
                gridTemplate="1.15fr 1.15fr .95fr .8fr 1.6fr .65fr .6fr .9fr 48px"
                rows={filteredResults}
                getRowKey={(result) => result.id}
                minWidth="1040px"
                empty={(
                    <EmptyState
                        icon={Activity}
                        title={searchTerm ? "Nenhum resultado para sua busca" : "Nenhum Diagnóstico Registrado"}
                        description={searchTerm
                            ? `Não foram encontrados diagnósticos para "${searchTerm}".`
                            : "Os diagnósticos feitos pelos clientes no app aparecerão aqui automaticamente com identificação de OLT e bairro."}
                    />
                )}
                renderRow={(result) => {
                    const meta = VERDICT_META[result.verdict] ?? { label: '-', tone: 'gray' as const };
                    const providerSupport = needsProvider(result);
                    return (
                        <div className="grid items-center gap-x-3 border-b border-[#F2F4F7] px-[18px] py-[11px] transition-colors hover:bg-[#F8FAFC]" style={{ gridTemplateColumns: "1.15fr 1.15fr .95fr .8fr 1.6fr .65fr .6fr .9fr 48px" }}>
                            <span className="min-w-0">
                                <span className="block truncate text-[13px] font-semibold text-[#1A2233]">
                                    {result.clientName || (result.contratoId ? `Contrato ${result.contratoId}` : '—')}
                                </span>
                                <span className="block truncate text-[11.5px] text-[#98A1B1]">
                                    {[result.contratoId ? `#${result.contratoId}` : '', result.planName].filter(Boolean).join(' · ') || '-'}
                                </span>
                            </span>
                            <span className="min-w-0">
                                <span className="block truncate text-[12.5px] font-medium text-[#1A2233]">{result.oltName || '—'}</span>
                                <span className="block truncate text-[11.5px] text-[#98A1B1]">{[result.bairro, result.cidade].filter(Boolean).join(' - ') || '—'}</span>
                            </span>
                            <span className="text-[12px] text-[#687181]">{formatDate(result.createdAt)}</span>
                            <StatusBadge status={meta.label} tone={meta.tone} />
                            <span className="truncate text-[12.5px] text-[#4A5364]" title={result.verdictHeadline}>{result.verdictHeadline || '-'}</span>
                            <span className="text-right font-mono text-[12px] text-[#4A5364]">{num(result.summary?.downloadMbps)}</span>
                            <span className="text-right font-mono text-[12px] text-[#4A5364]">
                                {result.summary?.pingMs != null ? `${num(result.summary.pingMs, 0)}ms` : '-'}
                            </span>
                            <StatusBadge
                                status={providerSupport ? 'Provedor' : 'Cliente'}
                                tone={providerSupport ? 'amber' : 'gray'}
                            />
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
                                                Esta ação não pode ser desfeita. O registro do diagnóstico do contrato {result.contratoId || '—'} será permanentemente excluído.
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
                    );
                }}
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
