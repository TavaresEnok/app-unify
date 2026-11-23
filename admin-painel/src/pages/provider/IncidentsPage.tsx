import { useEffect, useMemo, useState } from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { useSettings } from '@/contexts/SettingsContext';
import { toast } from 'sonner';
import { Loader2, TriangleAlert, Megaphone, Trash2, Send, Users, Smartphone, Radio } from 'lucide-react';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Switch } from '@/components/ui/switch';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import StatusBadge from '@/components/StatusBadge';
import {
    createIncident,
    deleteIncident,
    setIncidentActive,
    subscribeIncidents,
    type Incident,
    type IncidentSeverity,
} from '@/features/incidents/incidentService';
import {
    fetchNotificationSegments,
    previewNotificationAudience,
    sendNotificationCampaign,
    type AudiencePreviewData,
    type SegmentFilters,
    type SegmentOptionsData,
} from '@/shared/api/notifications';
import { fetchOutageRadar, type OutageCluster } from '@/shared/api/diagnostics';

function formatDate(ts?: { toDate: () => Date } | null): string {
    if (!ts) return '-';
    try {
        return ts.toDate().toLocaleString('pt-BR', {
            day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit',
        });
    } catch {
        return '-';
    }
}

const SEVERITY_BADGE: Record<IncidentSeverity, { label: string; tone: 'blue' | 'amber' | 'red' }> = {
    info: { label: 'Informativo', tone: 'blue' },
    warning: { label: 'Atenção', tone: 'amber' },
    critical: { label: 'Crítica', tone: 'red' },
};

export default function IncidentsPage() {
    const navigate = useNavigate();
    const location = useLocation();
    const radarDraft = (location.state as { radarCluster?: OutageCluster } | null)?.radarCluster;
    const { providerId } = useSettings();
    const [incidents, setIncidents] = useState<Incident[]>([]);
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [radarClusters, setRadarClusters] = useState<OutageCluster[]>([]);

    const [title, setTitle] = useState(
        radarDraft ? `Instabilidade identificada em ${radarDraft.areaName}`.slice(0, 80) : '',
    );
    const [message, setMessage] = useState(
        radarDraft ? 'Identificamos instabilidade na sua região e nossa equipe técnica já está atuando para normalizar a conexão.' : '',
    );
    const [area, setArea] = useState(radarDraft ? radarDraft.areaName.slice(0, 80) : '');
    const [severity, setSeverity] = useState<IncidentSeverity>(radarDraft ? 'critical' : 'warning');
    const [estimatedResolution, setEstimatedResolution] = useState('');

    // Segmentação real do PostgreSQL (OLT / Bairro / Cidade)
    const [segments, setSegments] = useState<SegmentOptionsData | null>(null);
    const [selectedOlt, setSelectedOlt] = useState(radarDraft?.scope === 'olt' ? radarDraft.areaName : '__all__');
    const [selectedBairro, setSelectedBairro] = useState(radarDraft?.scope === 'bairro' ? radarDraft.areaName : '__all__');
    const [selectedCidade, setSelectedCidade] = useState('__all__');

    // Disparo integrado de push em 1 clique
    const [sendPushNow, setSendPushNow] = useState(Boolean(radarDraft));
    const [preview, setPreview] = useState<AudiencePreviewData | null>(null);
    const [previewLoading, setPreviewLoading] = useState(false);

    useEffect(() => {
        if (!providerId) return;
        const unsubscribe = subscribeIncidents(providerId, (data) => {
            setIncidents(data);
            setLoading(false);
        }, () => {
            toast.error('Erro ao carregar instabilidades');
            setLoading(false);
        });
        return () => unsubscribe();
    }, [providerId]);

    useEffect(() => {
        if (!providerId) return;
        let alive = true;
        fetchNotificationSegments(providerId)
            .then((data) => { if (alive) setSegments(data); })
            .catch(() => { /* fallback: campo texto livre continua disponível */ });
        fetchOutageRadar(providerId)
            .then((clusters) => { if (alive) setRadarClusters(clusters); })
            .catch(() => { /* silencioso */ });
        return () => { alive = false; };
    }, [providerId]);

    const applyRadarCluster = (cluster: OutageCluster) => {
        setTitle(`Instabilidade identificada em ${cluster.areaName}`.slice(0, 80));
        setMessage('Identificamos instabilidade na sua região e nossa equipe técnica já está atuando para normalizar a conexão.');
        setArea(cluster.areaName.slice(0, 80));
        setSeverity('critical');
        setSelectedOlt(cluster.scope === 'olt' ? cluster.areaName : '__all__');
        setSelectedBairro(cluster.scope === 'bairro' ? cluster.areaName : '__all__');
        setSelectedCidade('__all__');
        setSendPushNow(true);
        toast.info(`Formulário preenchido para ${cluster.areaName}. Revise e publique.`);
    };

    const pushFilters = useMemo<SegmentFilters>(() => {
        const filters: SegmentFilters = {};
        if (selectedOlt !== '__all__') filters.oltNames = [selectedOlt];
        if (selectedBairro !== '__all__') filters.bairros = [selectedBairro];
        if (selectedCidade !== '__all__') filters.cidades = [selectedCidade];
        return filters;
    }, [selectedOlt, selectedBairro, selectedCidade]);

    // Mantém o texto de `area` sincronizado quando escolhe OLT/Bairro/Cidade
    const syncAreaLabel = (nextOlt: string, nextBairro: string, nextCidade: string) => {
        const parts = [
            nextOlt !== '__all__' ? nextOlt : '',
            nextBairro !== '__all__' ? nextBairro : '',
            nextCidade !== '__all__' ? nextCidade : '',
        ].filter(Boolean);
        if (parts.length > 0) setArea(parts.join(' · ').slice(0, 80));
    };

    useEffect(() => {
        if (!providerId || !sendPushNow) {
            setPreview(null);
            return;
        }
        let alive = true;
        setPreviewLoading(true);
        const timer = window.setTimeout(() => {
            previewNotificationAudience(providerId, pushFilters)
                .then((data) => { if (alive) setPreview(data); })
                .catch(() => { if (alive) setPreview(null); })
                .finally(() => { if (alive) setPreviewLoading(false); });
        }, 180);
        return () => {
            alive = false;
            window.clearTimeout(timer);
        };
    }, [providerId, sendPushNow, pushFilters]);

    const handleCreate = async () => {
        if (!providerId) return;
        if (!title.trim() || !message.trim()) {
            toast.error('Informe um título e uma mensagem.');
            return;
        }
        setSaving(true);
        try {
            await createIncident(providerId, {
                title,
                message,
                area,
                severity,
                estimatedResolution,
            });

            if (sendPushNow) {
                try {
                    const res = await sendNotificationCampaign({
                        providerId,
                        title: title.trim(),
                        body: estimatedResolution.trim()
                            ? `${message.trim()} Previsão: ${estimatedResolution.trim()}.`
                            : message.trim(),
                        category: severity === 'critical' ? 'urgent' : severity,
                        route: '/diagnostico',
                        filters: pushFilters,
                    });
                    toast.success(`Aviso publicado e push enviado (${res.data.successCount} entregue(s)).`);
                } catch (pushError) {
                    console.error('Error sending incident push:', pushError);
                    toast.warning('Aviso publicado no app, mas houve erro ao disparar o push.');
                }
            } else {
                toast.success('Aviso publicado. Os clientes verão o banner no app.');
            }

            setTitle('');
            setMessage('');
            setArea('');
            setEstimatedResolution('');
            setSeverity('warning');
            setSelectedOlt('__all__');
            setSelectedBairro('__all__');
            setSelectedCidade('__all__');
            setSendPushNow(false);
        } catch {
            toast.error('Não foi possível publicar o aviso.');
        } finally {
            setSaving(false);
        }
    };

    const handleToggle = async (incident: Incident) => {
        if (!providerId) return;
        try {
            await setIncidentActive(providerId, incident.id, !incident.active);
            toast.success(incident.active ? 'Aviso encerrado.' : 'Aviso reativado.');
        } catch {
            toast.error('Não foi possível atualizar o aviso.');
        }
    };

    const handleDelete = async (incident: Incident) => {
        if (!providerId) return;
        try {
            await deleteIncident(providerId, incident.id);
            toast.success('Aviso removido.');
        } catch {
            toast.error('Não foi possível remover o aviso.');
        }
    };

    return (
        <div className="flex flex-col gap-4">
            {radarClusters.length > 0 && (
                <Card className="border-amber-200 bg-amber-50/70">
                    <CardHeader className="pb-2">
                        <CardTitle className="flex items-center gap-2 text-[15px] text-amber-900">
                            <Radio className="h-4 w-4 text-amber-600" />
                            Radar automático de quedas (últimos 45 min)
                        </CardTitle>
                        <p className="text-[12.5px] text-amber-800/90">
                            Múltiplos assinantes na mesma OLT ou bairro registraram diagnósticos críticos/degradados recentemente.
                        </p>
                    </CardHeader>
                    <CardContent className="grid gap-2">
                        {radarClusters.map((cluster) => (
                            <div
                                key={`${cluster.scope}:${cluster.areaName}`}
                                className="flex flex-wrap items-center justify-between gap-2 rounded-lg border border-amber-200 bg-white px-3 py-2"
                            >
                                <div className="min-w-0">
                                    <div className="flex items-center gap-2">
                                        <span className="text-[13px] font-semibold text-[#1A2233]">
                                            {cluster.scope === 'olt' ? 'OLT' : 'Bairro'}: {cluster.areaName}
                                        </span>
                                        <StatusBadge
                                            status={`${cluster.distinctSubscribers} cliente(s)`}
                                            tone={cluster.criticalCount > 0 ? 'red' : 'amber'}
                                        />
                                    </div>
                                    <div className="text-[11.5px] text-[#687181]">
                                        {cluster.criticalCount} crítico(s), {cluster.degradedCount} atenção
                                        {cluster.cidade ? ` · ${cluster.cidade}` : ''}
                                    </div>
                                </div>
                                <Button
                                    size="sm"
                                    variant="outline"
                                    className="gap-1.5"
                                    onClick={() => applyRadarCluster(cluster)}
                                >
                                    <TriangleAlert className="h-3.5 w-3.5 text-amber-600" />
                                    Preencher aviso + push
                                </Button>
                            </div>
                        ))}
                    </CardContent>
                </Card>
            )}

            <Card>
                <CardHeader>
                    <CardTitle className="flex items-center gap-2">
                        <Megaphone className="h-5 w-5" /> Publicar aviso de instabilidade
                    </CardTitle>
                    <p className="text-[13px] text-muted-foreground">
                        O aviso aparece como banner no aplicativo para os clientes da região selecionada e,
                        opcionalmente, dispara notificação push imediata para a OLT, bairro ou cidade afetados.
                    </p>
                </CardHeader>
                <CardContent className="grid gap-3">
                    <div className="grid gap-3 sm:grid-cols-[1fr_180px]">
                        <div className="grid gap-1.5">
                            <label className="text-[13px] font-medium">Título</label>
                            <Input
                                value={title}
                                onChange={(e) => setTitle(e.target.value.slice(0, 80))}
                                placeholder="Ex.: Rompimento de fibra na região Pau Amarelo"
                                disabled={saving}
                            />
                        </div>
                        <div className="grid gap-1.5">
                            <label className="text-[13px] font-medium">Severidade</label>
                            <Select value={severity} onValueChange={(v) => setSeverity(v as IncidentSeverity)} disabled={saving}>
                                <SelectTrigger>
                                    <SelectValue />
                                </SelectTrigger>
                                <SelectContent>
                                    <SelectItem value="warning">Atenção</SelectItem>
                                    <SelectItem value="critical">Crítica (queda)</SelectItem>
                                    <SelectItem value="info">Informativo / manutenção</SelectItem>
                                </SelectContent>
                            </Select>
                        </div>
                    </div>

                    <div className="grid gap-1.5">
                        <label className="text-[13px] font-medium">Mensagem</label>
                        <Textarea
                            value={message}
                            onChange={(e) => setMessage(e.target.value)}
                            rows={3}
                            placeholder="Nossa equipe já está atuando para normalizar a conexão na sua região."
                            disabled={saving}
                        />
                    </div>

                    {segments && (segments.olts.length > 0 || segments.bairros.length > 0 || segments.cidades.length > 0) && (
                        <div className="grid gap-3 rounded-lg border border-[#EEF0F4] bg-[#F8FAFC] p-3 sm:grid-cols-3">
                            <div className="grid gap-1">
                                <label className="text-[12px] font-medium text-[#4A5364]">OLT afetada (SGP)</label>
                                <Select
                                    value={selectedOlt}
                                    onValueChange={(v) => {
                                        setSelectedOlt(v);
                                        syncAreaLabel(v, selectedBairro, selectedCidade);
                                    }}
                                    disabled={saving}
                                >
                                    <SelectTrigger className="bg-white">
                                        <SelectValue placeholder="Todas as OLTs" />
                                    </SelectTrigger>
                                    <SelectContent>
                                        <SelectItem value="__all__">Todas as OLTs</SelectItem>
                                        {segments.olts.map((o) => (
                                            <SelectItem key={o.value} value={o.value}>
                                                {o.value} ({o.count})
                                            </SelectItem>
                                        ))}
                                    </SelectContent>
                                </Select>
                            </div>
                            <div className="grid gap-1">
                                <label className="text-[12px] font-medium text-[#4A5364]">Bairro afetado</label>
                                <Select
                                    value={selectedBairro}
                                    onValueChange={(v) => {
                                        setSelectedBairro(v);
                                        syncAreaLabel(selectedOlt, v, selectedCidade);
                                    }}
                                    disabled={saving}
                                >
                                    <SelectTrigger className="bg-white">
                                        <SelectValue placeholder="Todos os bairros" />
                                    </SelectTrigger>
                                    <SelectContent>
                                        <SelectItem value="__all__">Todos os bairros</SelectItem>
                                        {segments.bairros.map((b) => (
                                            <SelectItem key={b.value} value={b.value}>
                                                {b.value} ({b.count})
                                            </SelectItem>
                                        ))}
                                    </SelectContent>
                                </Select>
                            </div>
                            <div className="grid gap-1">
                                <label className="text-[12px] font-medium text-[#4A5364]">Cidade afetada</label>
                                <Select
                                    value={selectedCidade}
                                    onValueChange={(v) => {
                                        setSelectedCidade(v);
                                        syncAreaLabel(selectedOlt, selectedBairro, v);
                                    }}
                                    disabled={saving}
                                >
                                    <SelectTrigger className="bg-white">
                                        <SelectValue placeholder="Todas as cidades" />
                                    </SelectTrigger>
                                    <SelectContent>
                                        <SelectItem value="__all__">Todas as cidades</SelectItem>
                                        {segments.cidades.map((c) => (
                                            <SelectItem key={c.value} value={c.value}>
                                                {c.value} ({c.count})
                                            </SelectItem>
                                        ))}
                                    </SelectContent>
                                </Select>
                            </div>
                        </div>
                    )}

                    <div className="grid gap-3 sm:grid-cols-2">
                        <div className="grid gap-1.5">
                            <label className="text-[13px] font-medium">Descrição da região (exibida no banner)</label>
                            <Input
                                value={area}
                                onChange={(e) => setArea(e.target.value.slice(0, 80))}
                                placeholder="Ex.: Pau Amarelo / OLT ZTE 01 (vazio = toda a rede)"
                                disabled={saving}
                            />
                        </div>
                        <div className="grid gap-1.5">
                            <label className="text-[13px] font-medium">Previsão de retorno (opcional)</label>
                            <Input
                                value={estimatedResolution}
                                onChange={(e) => setEstimatedResolution(e.target.value.slice(0, 60))}
                                placeholder="Ex.: Hoje até 18h"
                                disabled={saving}
                            />
                        </div>
                    </div>

                    <div className="flex flex-col gap-2 rounded-lg border border-[#EEF0F4] p-3">
                        <div className="flex items-center justify-between gap-3">
                            <div>
                                <div className="text-[13px] font-semibold text-[#1A2233]">
                                    Também enviar notificação push agora
                                </div>
                                <div className="text-[12px] text-[#687181]">
                                    {selectedOlt !== '__all__' || selectedBairro !== '__all__' || selectedCidade !== '__all__'
                                        ? 'Enviará apenas para os clientes dos filtros de OLT/bairro/cidade selecionados.'
                                        : 'Nenhum filtro de OLT/bairro selecionado: enviará para todos os clientes do provedor.'}
                                </div>
                            </div>
                            <Switch checked={sendPushNow} onCheckedChange={setSendPushNow} disabled={saving} />
                        </div>

                        {sendPushNow && (
                            <div className="flex flex-wrap items-center gap-4 border-t border-[#F2F4F7] pt-2 text-[12px] text-[#4A5364]">
                                {previewLoading ? (
                                    <span className="inline-flex items-center gap-1.5 text-[#687181]">
                                        <Loader2 className="h-3.5 w-3.5 animate-spin" />
                                        Calculando público afetado...
                                    </span>
                                ) : preview ? (
                                    <>
                                        <span className="inline-flex items-center gap-1.5">
                                            <Users className="h-3.5 w-3.5 text-[#687181]" />
                                            <strong>{preview.matchedSubscribers}</strong> cliente(s) na região
                                        </span>
                                        <span className="inline-flex items-center gap-1.5">
                                            <Smartphone className="h-3.5 w-3.5 text-[#687181]" />
                                            <strong>{preview.reachableDevices}</strong> dispositivo(s) com push ativo
                                        </span>
                                    </>
                                ) : null}
                            </div>
                        )}
                    </div>

                    <div>
                        <Button onClick={handleCreate} disabled={saving} className="gap-2">
                            {saving ? <Loader2 className="h-4 w-4 animate-spin" /> : sendPushNow ? <Send className="h-4 w-4" /> : <TriangleAlert className="h-4 w-4" />}
                            {sendPushNow ? 'Publicar aviso e enviar push' : 'Publicar aviso'}
                        </Button>
                    </div>
                </CardContent>
            </Card>

            <Card>
                <CardHeader>
                    <CardTitle>Avisos</CardTitle>
                </CardHeader>
                <CardContent>
                    {loading ? (
                        <div className="flex items-center justify-center py-8">
                            <Loader2 className="h-6 w-6 animate-spin" />
                        </div>
                    ) : incidents.length === 0 ? (
                        <p className="py-6 text-center text-[13px] text-muted-foreground">
                            Nenhum aviso publicado. Publique um acima quando houver instabilidade.
                        </p>
                    ) : (
                        <div className="flex flex-col divide-y divide-[#F2F4F7]">
                            {incidents.map((incident) => {
                                const sev = SEVERITY_BADGE[incident.severity || 'warning'] || SEVERITY_BADGE.warning;
                                return (
                                    <div key={incident.id} className="flex items-start justify-between gap-3 py-3">
                                        <div className="min-w-0">
                                            <div className="flex flex-wrap items-center gap-2">
                                                <span className="text-[13.5px] font-semibold text-[#1A2233]">{incident.title}</span>
                                                <StatusBadge
                                                    status={incident.active ? 'Ativo' : 'Encerrado'}
                                                    tone={incident.active ? 'red' : 'gray'}
                                                />
                                                <StatusBadge status={sev.label} tone={sev.tone} />
                                            </div>
                                            <div className="mt-0.5 text-[12.5px] text-[#687181]">{incident.message}</div>
                                            <div className="mt-1 text-[11.5px] text-[#98A1B1]">
                                                {incident.area ? `Região: ${incident.area} · ` : ''}
                                                {incident.estimatedResolution ? `Previsão: ${incident.estimatedResolution} · ` : ''}
                                                criado {formatDate(incident.createdAt)}
                                                {!incident.active && incident.resolvedAt ? ` · encerrado ${formatDate(incident.resolvedAt)}` : ''}
                                            </div>
                                        </div>
                                        <div className="flex shrink-0 items-center gap-2">
                                            {incident.active && (
                                                <Button
                                                    variant="outline"
                                                    size="sm"
                                                    className="gap-1.5"
                                                    onClick={() => navigate('../notificacoes', {
                                                        state: {
                                                            title: incident.title,
                                                            body: incident.message,
                                                            category: incident.severity === 'critical' ? 'urgent' : 'warning',
                                                            search: incident.area || '',
                                                        },
                                                    })}
                                                >
                                                    <Send className="h-3.5 w-3.5" />
                                                    Notificar push
                                                </Button>
                                            )}
                                            <Button variant="outline" size="sm" onClick={() => handleToggle(incident)}>
                                                {incident.active ? 'Encerrar' : 'Reativar'}
                                            </Button>
                                            <Button variant="ghost" size="icon" className="h-8 w-8 text-destructive hover:text-destructive"
                                                onClick={() => handleDelete(incident)}>
                                                <Trash2 className="h-4 w-4" />
                                            </Button>
                                        </div>
                                    </div>
                                );
                            })}
                        </div>
                    )}
                </CardContent>
            </Card>
        </div>
    );
}
