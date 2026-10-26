import { useEffect, useState } from 'react';
import { useAuth } from '@/contexts/AuthContext';
import { toast } from 'sonner';
import { Loader2, TriangleAlert, Megaphone, Trash2 } from 'lucide-react';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import StatusBadge from '@/components/StatusBadge';
import {
    createIncident,
    deleteIncident,
    setIncidentActive,
    subscribeIncidents,
    type Incident,
} from '@/features/incidents/incidentService';

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

export default function IncidentsPage() {
    const { providerId } = useAuth();
    const [incidents, setIncidents] = useState<Incident[]>([]);
    const [loading, setLoading] = useState(true);
    const [saving, setSaving] = useState(false);
    const [title, setTitle] = useState('');
    const [message, setMessage] = useState('');
    const [area, setArea] = useState('');

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

    const handleCreate = async () => {
        if (!providerId) return;
        if (!title.trim() || !message.trim()) {
            toast.error('Informe um título e uma mensagem.');
            return;
        }
        setSaving(true);
        try {
            await createIncident(providerId, { title, message, area });
            setTitle(''); setMessage(''); setArea('');
            toast.success('Aviso publicado. Os clientes verão no app ao diagnosticar.');
        } catch {
            toast.error('Não foi possível publicar o aviso.');
        }
        setSaving(false);
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
            <Card>
                <CardHeader>
                    <CardTitle className="flex items-center gap-2">
                        <Megaphone className="h-5 w-5" /> Publicar aviso de instabilidade
                    </CardTitle>
                    <p className="text-[13px] text-muted-foreground">
                        Quando um cliente rodar o diagnóstico e o problema apontar a rede, o app mostra
                        este aviso em vez de gerar mais um chamado do mesmo problema.
                    </p>
                </CardHeader>
                <CardContent className="grid gap-3">
                    <div className="grid gap-1.5">
                        <label className="text-[13px] font-medium">Título</label>
                        <Input value={title} onChange={(e) => setTitle(e.target.value.slice(0, 80))}
                            placeholder="Ex.: Rompimento de fibra na região Centro" disabled={saving} />
                    </div>
                    <div className="grid gap-1.5">
                        <label className="text-[13px] font-medium">Mensagem</label>
                        <Textarea value={message} onChange={(e) => setMessage(e.target.value)} rows={3}
                            placeholder="Nossa equipe já está atuando para normalizar. Previsão de retorno em algumas horas."
                            disabled={saving} />
                    </div>
                    <div className="grid gap-1.5">
                        <label className="text-[13px] font-medium">Região afetada (opcional)</label>
                        <Input value={area} onChange={(e) => setArea(e.target.value.slice(0, 80))}
                            placeholder="Ex.: Bairro Centro / POP Norte" disabled={saving} />
                    </div>
                    <div>
                        <Button onClick={handleCreate} disabled={saving} className="gap-2">
                            {saving ? <Loader2 className="h-4 w-4 animate-spin" /> : <TriangleAlert className="h-4 w-4" />}
                            Publicar aviso
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
                            {incidents.map((incident) => (
                                <div key={incident.id} className="flex items-start justify-between gap-3 py-3">
                                    <div className="min-w-0">
                                        <div className="flex items-center gap-2">
                                            <span className="text-[13.5px] font-semibold text-[#1A2233]">{incident.title}</span>
                                            <StatusBadge
                                                status={incident.active ? 'Ativo' : 'Encerrado'}
                                                tone={incident.active ? 'red' : 'gray'}
                                            />
                                        </div>
                                        <div className="mt-0.5 text-[12.5px] text-[#687181]">{incident.message}</div>
                                        <div className="mt-1 text-[11.5px] text-[#98A1B1]">
                                            {incident.area ? `Região: ${incident.area} · ` : ''}
                                            criado {formatDate(incident.createdAt)}
                                            {!incident.active && incident.resolvedAt ? ` · encerrado ${formatDate(incident.resolvedAt)}` : ''}
                                        </div>
                                    </div>
                                    <div className="flex shrink-0 items-center gap-2">
                                        <Button variant="outline" size="sm" onClick={() => handleToggle(incident)}>
                                            {incident.active ? 'Encerrar' : 'Reativar'}
                                        </Button>
                                        <Button variant="ghost" size="icon" className="h-8 w-8 text-destructive hover:text-destructive"
                                            onClick={() => handleDelete(incident)}>
                                            <Trash2 className="h-4 w-4" />
                                        </Button>
                                    </div>
                                </div>
                            ))}
                        </div>
                    )}
                </CardContent>
            </Card>
        </div>
    );
}
