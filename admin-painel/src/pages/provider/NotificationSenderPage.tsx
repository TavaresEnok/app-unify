import { useCallback, useEffect, useMemo, useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import { Switch } from "@/components/ui/switch";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import StatusBadge from '@/components/StatusBadge';
import { useAuth } from '@/contexts/AuthContext';
import { useSettings } from '@/contexts/SettingsContext';
import { useLocation } from 'react-router-dom';
import { toast } from 'sonner';
import {
  Send,
  Loader2,
  RefreshCw,
  Filter,
  Users,
  Smartphone,
  X,
  Radio,
  MapPin,
  Cpu,
  Download,
  CalendarClock,
  Receipt,
} from 'lucide-react';
import {
  cancelScheduledNotification,
  fetchBillingPushRule,
  fetchNotificationHistory,
  fetchNotificationSegments,
  previewNotificationAudience,
  saveBillingPushRule,
  sendNotificationCampaign,
  syncNotificationSegments,
  type AudiencePreviewData,
  type BillingPushRule,
  type CampaignHistoryItem,
  type SegmentFilters,
  type SegmentOption,
  type SegmentOptionsData,
} from '@/shared/api/notifications';

const routeOptions = [
  { value: 'none', label: 'Tela inicial do app' },
  { value: '/faturas', label: 'Faturas (Pix e boleto)' },
  { value: '/diagnostico', label: 'Diagnóstico da conexão' },
  { value: '/notificacoes', label: 'Central de avisos' },
];

interface DraftState {
  title?: string;
  body?: string;
  category?: string;
  search?: string;
  bairro?: string;
  targetCpf?: string;
}

function MultiSelectField({
  label,
  placeholder,
  options,
  selected,
  onChange,
  disabled,
  formatLabel,
}: {
  label: string;
  placeholder: string;
  options: SegmentOption[];
  selected: string[];
  onChange: (next: string[]) => void;
  disabled?: boolean;
  formatLabel?: (opt: SegmentOption) => string;
}) {
  const [pick, setPick] = useState('');
  const available = useMemo(
    () => options.filter((opt) => !selected.includes(opt.value)),
    [options, selected],
  );

  const handleSelect = (val: string) => {
    if (!val || selected.includes(val)) return;
    onChange([...selected, val]);
    setPick('');
  };

  const remove = (val: string) => onChange(selected.filter((item) => item !== val));

  return (
    <div className="grid gap-1.5">
      <Label className="text-[12.5px] font-medium text-[#2F3748]">{label}</Label>
      <Select
        value={pick}
        onValueChange={handleSelect}
        disabled={disabled || available.length === 0}
      >
        <SelectTrigger className="h-9 text-[13px]">
          <SelectValue
            placeholder={
              options.length === 0
                ? 'Sem dados indexados'
                : available.length === 0
                  ? 'Todos selecionados'
                  : placeholder
            }
          />
        </SelectTrigger>
        <SelectContent className="max-h-64">
          {available.map((opt) => (
            <SelectItem key={opt.value} value={opt.value}>
              {formatLabel ? formatLabel(opt) : opt.value} ({opt.count})
            </SelectItem>
          ))}
        </SelectContent>
      </Select>
      {selected.length > 0 && (
        <div className="flex flex-wrap gap-1.5 pt-0.5">
          {selected.map((val) => {
            const opt = options.find((o) => o.value === val);
            const text = opt && formatLabel ? formatLabel(opt) : val;
            return (
              <span
                key={val}
                className="inline-flex items-center gap-1 rounded-full border border-[#D4DFEE] bg-[#F2F6FC] px-2.5 py-0.5 text-[11.5px] font-medium text-[#1E3A6D]"
              >
                <span className="max-w-[200px] truncate">{text}</span>
                <button
                  type="button"
                  onClick={() => remove(val)}
                  disabled={disabled}
                  aria-label={`Remover ${text}`}
                  className="rounded-full p-0.5 hover:bg-[#DCE7F7]"
                >
                  <X className="h-3 w-3" />
                </button>
              </span>
            );
          })}
        </div>
      )}
    </div>
  );
}

function summarizeFilters(filters: Required<SegmentFilters>): string[] {
  const tags: string[] = [];
  if (filters.oltNames?.length) tags.push(`OLT: ${filters.oltNames.join(', ')}`);
  if (filters.ponKeys?.length) tags.push(`PON: ${filters.ponKeys.join(', ')}`);
  if (filters.ctos?.length) tags.push(`CTO: ${filters.ctos.join(', ')}`);
  if (filters.cidades?.length) tags.push(`Cidade: ${filters.cidades.join(', ')}`);
  if (filters.bairros?.length) tags.push(`Bairro: ${filters.bairros.join(', ')}`);
  if (filters.popIds?.length) tags.push(`POP: ${filters.popIds.join(', ')}`);
  if (filters.statuses?.length) tags.push(`Status: ${filters.statuses.join(', ')}`);
  if (filters.planos?.length) tags.push(`Plano: ${filters.planos.join(', ')}`);
  if (filters.targetCpf) tags.push(`CPF: ${filters.targetCpf}`);
  if (filters.search) tags.push(`Busca: "${filters.search}"`);
  return tags;
}

export default function NotificationSenderPage({ historyOnly = false }: { historyOnly?: boolean }) {
  const location = useLocation();
  const draft = location.state as DraftState | null;
  const { user } = useAuth();
  const { providerId } = useSettings();

  // Mensagem
  const [title, setTitle] = useState(draft?.title || '');
  const [body, setBody] = useState(draft?.body || '');
  const [category, setCategory] = useState(draft?.category || 'info');
  const [route, setRoute] = useState('none');
  const [scheduleEnabled, setScheduleEnabled] = useState(false);
  const [scheduledFor, setScheduledFor] = useState('');

  // Régua automática de cobrança (PostgreSQL)
  const [billingRule, setBillingRule] = useState<BillingPushRule | null>(null);
  const [savingBillingRule, setSavingBillingRule] = useState(false);

  // Filtros avançados (PostgreSQL)
  const [oltNames, setOltNames] = useState<string[]>([]);
  const [ponKeys, setPonKeys] = useState<string[]>([]);
  const [ctos, setCtos] = useState<string[]>([]);
  const [cidades, setCidades] = useState<string[]>([]);
  const [bairros, setBairros] = useState<string[]>(draft?.bairro ? [draft.bairro.toUpperCase()] : []);
  const [popIds, setPopIds] = useState<string[]>([]);
  const [statuses, setStatuses] = useState<string[]>([]);
  const [planos, setPlanos] = useState<string[]>([]);
  const [targetCpf, setTargetCpf] = useState(draft?.targetCpf || '');
  const [search, setSearch] = useState(draft?.search || '');

  // Dados do Postgres
  const [segments, setSegments] = useState<SegmentOptionsData | null>(null);
  const [segmentsLoading, setSegmentsLoading] = useState(false);
  const [syncing, setSyncing] = useState(false);
  const [preview, setPreview] = useState<AudiencePreviewData | null>(null);
  const [previewLoading, setPreviewLoading] = useState(false);
  const [sending, setSending] = useState(false);

  // Histórico (PostgreSQL)
  const [history, setHistory] = useState<CampaignHistoryItem[]>([]);
  const [historyLoading, setHistoryLoading] = useState(true);
  const [historyError, setHistoryError] = useState(false);

  const activeFilters: SegmentFilters = useMemo(() => ({
    oltNames,
    ponKeys,
    ctos,
    cidades,
    bairros,
    popIds,
    statuses,
    planos,
    targetCpf: targetCpf.replace(/\D/g, ''),
    search: search.trim(),
  }), [oltNames, ponKeys, ctos, cidades, bairros, popIds, statuses, planos, targetCpf, search]);

  const activeFilterCount = useMemo(() => (
    oltNames.length + ponKeys.length + ctos.length + cidades.length + bairros.length +
    popIds.length + statuses.length + planos.length +
    (targetCpf.replace(/\D/g, '') ? 1 : 0) + (search.trim() ? 1 : 0)
  ), [oltNames, ponKeys, ctos, cidades, bairros, popIds, statuses, planos, targetCpf, search]);

  const loadSegments = useCallback(async () => {
    if (!providerId || historyOnly) return;
    setSegmentsLoading(true);
    try {
      const data = await fetchNotificationSegments(providerId, { oltNames, ponKeys, cidades, bairros });
      setSegments(data);
    } catch {
      // Silencioso para não poluir enquanto navega
    } finally {
      setSegmentsLoading(false);
    }
  }, [providerId, historyOnly, oltNames, ponKeys, cidades, bairros]);

  useEffect(() => {
    void loadSegments();
  }, [loadSegments]);

  useEffect(() => {
    if (!providerId || historyOnly) return;
    let alive = true;
    fetchBillingPushRule(providerId)
      .then((rule) => { if (alive) setBillingRule(rule); })
      .catch(() => { /* silencioso */ });
    return () => { alive = false; };
  }, [providerId, historyOnly]);

  const toggleBillingOffset = (kind: 'before' | 'after', day: number) => {
    setBillingRule((prev) => {
      const current = prev || { providerId: providerId || '', enabled: true, daysBefore: [1], daysAfter: [], updatedAt: null };
      const list = kind === 'before' ? current.daysBefore : current.daysAfter;
      const next = list.includes(day) ? list.filter((d) => d !== day) : [...list, day];
      return kind === 'before' ? { ...current, daysBefore: next } : { ...current, daysAfter: next };
    });
  };

  const handleSaveBillingRule = async () => {
    if (!providerId || !billingRule) return;
    setSavingBillingRule(true);
    try {
      const res = await saveBillingPushRule(providerId, {
        enabled: billingRule.enabled,
        daysBefore: billingRule.daysBefore,
        daysAfter: billingRule.daysAfter,
      });
      setBillingRule(res.data);
      toast.success('Régua automática salva', { description: res.message });
    } catch (error) {
      toast.error('Erro ao salvar régua', {
        description: error instanceof Error ? error.message : 'Tente novamente.',
      });
    } finally {
      setSavingBillingRule(false);
    }
  };

  const handleCancelScheduled = async (campaignId: string) => {
    if (!providerId) return;
    try {
      await cancelScheduledNotification(providerId, campaignId);
      setHistory((prev) => prev.map((item) => (item.id === campaignId ? { ...item, status: 'cancelled' } : item)));
      toast.success('Agendamento cancelado.');
    } catch (error) {
      toast.error('Não foi possível cancelar', {
        description: error instanceof Error ? error.message : 'Tente novamente.',
      });
    }
  };

  useEffect(() => {
    if (!providerId || historyOnly) return;
    let cancelled = false;
    const timer = setTimeout(async () => {
      setPreviewLoading(true);
      try {
        const result = await previewNotificationAudience(providerId, activeFilters);
        if (!cancelled) setPreview(result);
      } catch {
        if (!cancelled) setPreview(null);
      } finally {
        if (!cancelled) setPreviewLoading(false);
      }
    }, 220);
    return () => { cancelled = true; clearTimeout(timer); };
  }, [providerId, historyOnly, activeFilters]);

  const loadHistory = useCallback(async () => {
    if (!providerId || !historyOnly) return;
    setHistoryLoading(true);
    setHistoryError(false);
    try {
      const rows = await fetchNotificationHistory(providerId, 40);
      setHistory(rows);
    } catch {
      setHistoryError(true);
    } finally {
      setHistoryLoading(false);
    }
  }, [providerId, historyOnly]);

  useEffect(() => {
    void loadHistory();
  }, [loadHistory]);

  const clearFilters = () => {
    setOltNames([]);
    setPonKeys([]);
    setCtos([]);
    setCidades([]);
    setBairros([]);
    setPopIds([]);
    setStatuses([]);
    setPlanos([]);
    setTargetCpf('');
    setSearch('');
  };

  const handleSyncSegments = async (importLegacyTokens = false) => {
    if (!providerId) return;
    setSyncing(true);
    try {
      const res = await syncNotificationSegments(providerId, importLegacyTokens);
      toast.success('Segmentos atualizados', { description: res.message });
      await loadSegments();
      const updatedPreview = await previewNotificationAudience(providerId, activeFilters);
      setPreview(updatedPreview);
    } catch (error) {
      toast.error('Falha ao sincronizar', {
        description: error instanceof Error ? error.message : 'Tente novamente.',
      });
    } finally {
      setSyncing(false);
    }
  };

  const handleSendNotification = async () => {
    if (!user || !providerId) {
      toast.error('Erro de autenticação', { description: 'Usuário ou provedor não identificado.' });
      return;
    }
    if (!title.trim() || !body.trim()) {
      toast.error('Campos obrigatórios', { description: 'Preencha título e mensagem antes de enviar.' });
      return;
    }

    let scheduledIso: string | null = null;
    if (scheduleEnabled) {
      if (!scheduledFor) {
        toast.error('Data obrigatória', { description: 'Escolha a data e hora do agendamento.' });
        return;
      }
      const parsed = new Date(scheduledFor);
      if (Number.isNaN(parsed.getTime()) || parsed.getTime() <= Date.now() + 60_000) {
        toast.error('Data inválida', { description: 'Escolha um horário pelo menos 1 minuto no futuro.' });
        return;
      }
      scheduledIso = parsed.toISOString();
    }

    if (activeFilterCount === 0) {
      const ok = window.confirm(
        scheduleEnabled
          ? 'Nenhum filtro foi selecionado. Agendar esta notificação para TODOS os clientes do aplicativo?'
          : 'Nenhum filtro foi selecionado. Enviar esta notificação para TODOS os clientes do aplicativo?',
      );
      if (!ok) return;
    }

    setSending(true);
    try {
      const res = await sendNotificationCampaign({
        providerId,
        title: title.trim(),
        body: body.trim(),
        category,
        route: route === 'none' ? '' : route,
        filters: activeFilters,
        scheduledFor: scheduledIso,
      });
      toast.success(scheduleEnabled ? 'Campanha agendada' : 'Campanha enviada', { description: res.message });
      setTitle('');
      setBody('');
      setScheduleEnabled(false);
      setScheduledFor('');
    } catch (error) {
      toast.error('Erro ao enviar', {
        description: error instanceof Error ? error.message : 'Não foi possível enviar a notificação.',
      });
    } finally {
      setSending(false);
    }
  };

  if (historyOnly) {
    return (
      <div className="space-y-4">
        <Card className="overflow-hidden">
          <CardHeader className="flex flex-row items-center justify-between border-b border-[#EEF0F4]">
            <div>
              <CardTitle>Histórico de envios</CardTitle>
              <p className="mt-0.5 text-[12.5px] text-[#687181]">
                Campanhas registradas no banco local (PostgreSQL) — sem custo de leitura no Firebase.
              </p>
            </div>
            <Button variant="outline" size="sm" onClick={() => void loadHistory()} disabled={historyLoading} className="gap-1.5">
              <RefreshCw className={`h-3.5 w-3.5 ${historyLoading ? 'animate-spin' : ''}`} />
              Atualizar
            </Button>
          </CardHeader>
          <CardContent className="p-0">
            {historyLoading && <p role="status" className="p-4 text-sm text-muted-foreground">Carregando histórico…</p>}
            {historyError && <p role="alert" className="p-4 text-sm text-destructive">Não foi possível carregar o histórico de envios.</p>}
            {!historyLoading && !historyError && history.length === 0 && (
              <div className="px-[18px] py-6 text-center text-[13px] text-[#98A1B1]">
                Nenhuma campanha enviada ainda por este painel.
              </div>
            )}
            {!historyLoading && !historyError && history.map((item) => {
              const tags = summarizeFilters(item.filters);
              const dateLabel = new Date(item.createdAt).toLocaleString('pt-BR', {
                day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit',
              });
              return (
                <div key={item.id} className="border-b border-[#F2F4F7] px-[18px] py-3.5 last:border-b-0">
                  <div className="flex flex-wrap items-baseline justify-between gap-2">
                    <div className="flex items-center gap-2 min-w-0">
                      <span className="truncate text-[13.5px] font-semibold text-[#1A2233]">{item.title}</span>
                      <StatusBadge
                        status={item.deliveryMode === 'topic' ? 'Todos' : 'Segmentado'}
                        tone={item.deliveryMode === 'topic' ? 'blue' : 'green'}
                      />
                      {item.status === 'scheduled' && <StatusBadge status="Agendado" tone="amber" />}
                      {item.status === 'cancelled' && <StatusBadge status="Cancelado" tone="gray" />}
                      {item.status === 'failed' && <StatusBadge status="Falhou" tone="red" />}
                    </div>
                    <div className="flex items-center gap-2">
                      <span className="shrink-0 text-[11.5px] text-[#98A1B1]">
                        {item.status === 'scheduled' && item.scheduledFor
                          ? `Agendado para ${new Date(item.scheduledFor).toLocaleString('pt-BR', { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' })}`
                          : dateLabel}
                      </span>
                      {item.status === 'scheduled' && (
                        <Button
                          variant="outline"
                          size="sm"
                          className="h-7 px-2 text-xs text-destructive"
                          onClick={() => void handleCancelScheduled(item.id)}
                        >
                          Cancelar
                        </Button>
                      )}
                    </div>
                  </div>
                  <p className="mt-1 text-[12.5px] text-[#5B6474] line-clamp-2">{item.body}</p>
                  {tags.length > 0 && (
                    <div className="mt-2 flex flex-wrap gap-1.5">
                      {tags.map((tag) => (
                        <span
                          key={tag}
                          className="rounded-md border border-[#E3E8F0] bg-[#F7F9FC] px-2 py-0.5 text-[11px] font-medium text-[#3B475C]"
                        >
                          {tag}
                        </span>
                      ))}
                    </div>
                  )}
                  <div className="mt-2 text-[11.5px] text-[#7D8798]">
                    {item.matchedSubscribers} assinante(s) no público ·{' '}
                    {item.deliveryMode === 'topic'
                      ? 'enviado via tópico geral do aplicativo'
                      : `${item.successCount} push(es) aceito(s)${item.failureCount > 0 ? ` · ${item.failureCount} falha(s)` : ''}`}
                  </div>
                </div>
              );
            })}
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {/* Bloco 1: Segmentação Avançada (PostgreSQL local) */}
      <Card className="overflow-hidden">
        <CardHeader className="flex flex-col gap-2 border-b border-[#EEF0F4] sm:flex-row sm:items-center sm:justify-between">
          <div>
            <CardTitle className="flex items-center gap-2">
              <Filter className="h-4 w-4 text-[#2456C9]" />
              Segmentação avançada de destinatários
            </CardTitle>
            <p className="mt-0.5 text-[12.5px] text-[#687181]">
              Filtre por OLT, Porta PON, CTO, Cidade, Bairro, Status do contrato ou Plano direto no PostgreSQL local (sem custo extra).
            </p>
          </div>
          <div className="flex flex-wrap items-center gap-2">
            {activeFilterCount > 0 && (
              <Button variant="ghost" size="sm" onClick={clearFilters} disabled={sending} className="gap-1 text-xs">
                <X className="h-3.5 w-3.5" /> Limpar ({activeFilterCount})
              </Button>
            )}
            <Button
              variant="outline"
              size="sm"
              onClick={() => void handleSyncSegments(false)}
              disabled={syncing || sending}
              className="gap-1.5 text-xs"
            >
              <RefreshCw className={`h-3.5 w-3.5 ${syncing ? 'animate-spin' : ''}`} />
              Reindexar SGP
            </Button>
          </div>
        </CardHeader>

        <CardContent className="space-y-4 p-[18px]">
          {/* Rede Óptica: OLT / PON / CTO */}
          <div className="space-y-2.5">
            <div className="flex items-center gap-1.5 text-[12px] font-semibold uppercase tracking-wide text-[#687181]">
              <Cpu className="h-3.5 w-3.5" /> Rede Óptica (Fibra)
            </div>
            <div className="grid gap-3 sm:grid-cols-3">
              <MultiSelectField
                label="OLT"
                placeholder="Todas as OLTs"
                options={segments?.olts ?? []}
                selected={oltNames}
                onChange={(next) => { setOltNames(next); setPonKeys([]); setCtos([]); }}
                disabled={sending || segmentsLoading}
              />
              <MultiSelectField
                label="Porta PON (Slot / PON)"
                placeholder={oltNames.length ? 'Filtrar PON desta OLT' : 'Todas as portas PON'}
                options={segments?.pons ?? []}
                selected={ponKeys}
                onChange={(next) => { setPonKeys(next); setCtos([]); }}
                disabled={sending || segmentsLoading}
                formatLabel={(opt) => opt.meta || opt.value}
              />
              <MultiSelectField
                label="CTO / Caixa (Splitter)"
                placeholder="Todas as CTOs"
                options={segments?.ctos ?? []}
                selected={ctos}
                onChange={setCtos}
                disabled={sending || segmentsLoading}
              />
            </div>
          </div>

          {/* Localização: Cidade / Bairro / POP */}
          <div className="space-y-2.5 border-t border-[#F2F4F7] pt-3.5">
            <div className="flex items-center gap-1.5 text-[12px] font-semibold uppercase tracking-wide text-[#687181]">
              <MapPin className="h-3.5 w-3.5" /> Localização e Região
            </div>
            <div className="grid gap-3 sm:grid-cols-3">
              <MultiSelectField
                label="Cidade"
                placeholder="Todas as cidades"
                options={segments?.cidades ?? []}
                selected={cidades}
                onChange={(next) => { setCidades(next); setBairros([]); }}
                disabled={sending || segmentsLoading}
              />
              <MultiSelectField
                label="Bairro / Região"
                placeholder={cidades.length ? 'Bairros da cidade selecionada' : 'Todos os bairros'}
                options={segments?.bairros ?? []}
                selected={bairros}
                onChange={setBairros}
                disabled={sending || segmentsLoading}
                formatLabel={(opt) => (opt.meta && cidades.length === 0 ? `${opt.value} (${opt.meta})` : opt.value)}
              />
              <MultiSelectField
                label="POP"
                placeholder="Todos os POPs"
                options={segments?.pops ?? []}
                selected={popIds}
                onChange={setPopIds}
                disabled={sending || segmentsLoading}
                formatLabel={(opt) => `POP ${opt.value}`}
              />
            </div>
          </div>

          {/* Contrato: Status / Plano / CPF / Busca */}
          <div className="space-y-2.5 border-t border-[#F2F4F7] pt-3.5">
            <div className="flex items-center gap-1.5 text-[12px] font-semibold uppercase tracking-wide text-[#687181]">
              <Users className="h-3.5 w-3.5" /> Contrato e Assinante
            </div>
            <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
              <MultiSelectField
                label="Status do contrato"
                placeholder="Todos os status"
                options={segments?.statuses ?? []}
                selected={statuses}
                onChange={setStatuses}
                disabled={sending || segmentsLoading}
              />
              <MultiSelectField
                label="Plano"
                placeholder="Todos os planos"
                options={segments?.planos ?? []}
                selected={planos}
                onChange={setPlanos}
                disabled={sending || segmentsLoading}
              />
              <div className="grid gap-1.5">
                <Label htmlFor="targetCpf" className="text-[12.5px] font-medium text-[#2F3748]">
                  CPF/CNPJ específico
                </Label>
                <Input
                  id="targetCpf"
                  className="h-9 text-[13px]"
                  placeholder="Opcional (somente dígitos)"
                  value={targetCpf}
                  onChange={(e) => setTargetCpf(e.target.value)}
                  disabled={sending}
                />
              </div>
              <div className="grid gap-1.5">
                <Label htmlFor="segmentSearch" className="text-[12.5px] font-medium text-[#2F3748]">
                  Busca livre (OLT/CTO/Bairro)
                </Label>
                <Input
                  id="segmentSearch"
                  className="h-9 text-[13px]"
                  placeholder="Ex.: PAU AMARELO"
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  disabled={sending}
                />
              </div>
            </div>
          </div>

          {/* Prévia em tempo real da audiência */}
          <div className="flex flex-col gap-3 rounded-xl border border-[#DCE6F5] bg-[#F5F8FE] p-3.5 sm:flex-row sm:items-center sm:justify-between">
            <div className="flex flex-wrap items-center gap-4">
              <div className="flex items-center gap-2">
                <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-[#E4EEFD] text-[#2456C9]">
                  {activeFilterCount === 0 ? <Radio className="h-4 w-4" /> : <Users className="h-4 w-4" />}
                </div>
                <div>
                  <div className="text-[11.5px] text-[#5B677B]">
                    {activeFilterCount === 0 ? 'Público geral (todos)' : 'Assinantes no segmento'}
                  </div>
                  <div className="text-[16px] font-bold text-[#1A2233]">
                    {previewLoading ? 'Calculando…' : `${preview?.matchedSubscribers ?? segments?.totals.totalSubscribers ?? 0}`}
                  </div>
                </div>
              </div>

              <div className="flex items-center gap-2 border-l border-[#D5E1F2] pl-4">
                <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-[#E6F5EC] text-[#147A3E]">
                  <Smartphone className="h-4 w-4" />
                </div>
                <div>
                  <div className="text-[11.5px] text-[#5B677B]">Aparelhos com push ativo</div>
                  <div className="text-[16px] font-bold text-[#1A2233]">
                    {previewLoading ? '…' : `${preview?.reachableDevices ?? segments?.totals.totalDevices ?? 0}`}
                  </div>
                </div>
              </div>
            </div>

            {segments && segments.totals.totalDevices === 0 && (
              <Button
                variant="outline"
                size="sm"
                onClick={() => void handleSyncSegments(true)}
                disabled={syncing || sending}
                className="gap-1.5 bg-white text-xs"
              >
                <Download className="h-3.5 w-3.5" />
                Importar tokens legados do app
              </Button>
            )}
          </div>
        </CardContent>
      </Card>

      {/* Bloco 2: Composição da Mensagem */}
      <Card className="overflow-hidden">
        <CardHeader className="border-b border-[#EEF0F4]">
          <CardTitle>Mensagem da notificação push</CardTitle>
          <p className="mt-0.5 text-[12.5px] text-[#687181]">
            {activeFilterCount === 0
              ? 'Será entregue para todos os celulares inscritos no aplicativo via tópico FCM.'
              : 'Será entregue apenas para os celulares que correspondem a todos os filtros acima e registrada na caixa de avisos do app.'}
          </p>
        </CardHeader>
        <CardContent className="p-[18px]">
          <div className="grid gap-3.5">
            <div className="grid gap-3.5 sm:grid-cols-2">
              <div className="grid gap-1.5">
                <Label htmlFor="category">Categoria</Label>
                <Select value={category} onValueChange={setCategory} disabled={sending}>
                  <SelectTrigger id="category"><SelectValue /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value="info">Informação</SelectItem>
                    <SelectItem value="urgent">Urgente (manutenção / queda)</SelectItem>
                    <SelectItem value="promo">Promoção</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="grid gap-1.5">
                <Label htmlFor="route">Abrir tela ao tocar</Label>
                <Select value={route} onValueChange={setRoute} disabled={sending}>
                  <SelectTrigger id="route"><SelectValue /></SelectTrigger>
                  <SelectContent>
                    {routeOptions.map((item) => (
                      <SelectItem key={item.value} value={item.value}>{item.label}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>

            <div className="grid gap-1.5">
              <Label htmlFor="title">Título</Label>
              <Input
                id="title"
                placeholder="Ex.: Manutenção programada — OLT Pau Amarelo"
                value={title}
                onChange={(e) => setTitle(e.target.value.slice(0, 80))}
                disabled={sending}
              />
            </div>

            <div className="grid gap-1.5">
              <Label htmlFor="body">Mensagem</Label>
              <Textarea
                id="body"
                placeholder="Escreva a mensagem que os clientes receberão..."
                value={body}
                onChange={(e) => setBody(e.target.value)}
                rows={4}
                disabled={sending}
              />
            </div>

            <div className="rounded-lg border border-[#EEF0F4] bg-[#F8FAFC] p-3">
              <div className="flex items-center justify-between gap-3">
                <div className="flex items-center gap-2">
                  <CalendarClock className="h-4 w-4 text-[#2456C9]" />
                  <div>
                    <div className="text-[13px] font-semibold text-[#1A2233]">Agendar envio futuro</div>
                    <div className="text-[11.5px] text-[#687181]">
                      Programe comunicados ou avisos de manutenção para data e hora específicas (até 30 dias).
                    </div>
                  </div>
                </div>
                <Switch checked={scheduleEnabled} onCheckedChange={setScheduleEnabled} disabled={sending} />
              </div>
              {scheduleEnabled && (
                <div className="mt-3 max-w-xs">
                  <Label htmlFor="scheduledFor" className="text-[12px] text-[#4A5364]">Data e hora do disparo</Label>
                  <Input
                    id="scheduledFor"
                    type="datetime-local"
                    value={scheduledFor}
                    onChange={(e) => setScheduledFor(e.target.value)}
                    disabled={sending}
                    className="mt-1 bg-white"
                  />
                </div>
              )}
            </div>

            <div className="flex flex-wrap items-center gap-3">
              <Button onClick={() => void handleSendNotification()} disabled={sending} className="w-fit gap-2">
                {sending
                  ? <Loader2 className="h-4 w-4 animate-spin" />
                  : scheduleEnabled
                    ? <CalendarClock className="h-4 w-4" />
                    : <Send className="h-4 w-4" />}
                {sending
                  ? (scheduleEnabled ? 'Agendando…' : 'Enviando…')
                  : scheduleEnabled
                    ? 'Agendar campanha'
                    : activeFilterCount === 0
                      ? 'Enviar para todos'
                      : `Enviar para segmento (${preview?.matchedSubscribers ?? 0})`}
              </Button>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Bloco 3: Régua Automática de Cobrança via Push */}
      {billingRule && (
        <Card className="overflow-hidden">
          <CardHeader className="flex flex-row items-center justify-between border-b border-[#EEF0F4]">
            <div>
              <CardTitle className="flex items-center gap-2 text-[15px]">
                <Receipt className="h-4 w-4 text-[#2456C9]" />
                Régua automática de lembretes de fatura (Push gratuito)
              </CardTitle>
              <p className="mt-0.5 text-[12.5px] text-[#687181]">
                Consulta o SGP apenas para contratos com vencimento na janela escolhida e envia push levando direto para o PIX/boleto no app.
              </p>
            </div>
            <Switch
              checked={billingRule.enabled}
              onCheckedChange={(checked) => setBillingRule((prev) => (prev ? { ...prev, enabled: checked } : prev))}
              disabled={savingBillingRule}
            />
          </CardHeader>
          <CardContent className="space-y-3 p-[18px]">
            <div className="flex flex-wrap gap-2">
              {([
                { kind: 'before', day: 3, label: '3 dias antes (D-3)' },
                { kind: 'before', day: 1, label: 'Véspera (D-1)' },
                { kind: 'before', day: 0, label: 'No vencimento (D-0)' },
                { kind: 'after', day: 3, label: '3 dias em atraso (D+3)' },
                { kind: 'after', day: 5, label: '5 dias em atraso (D+5)' },
              ] as const).map((item) => {
                const selected = item.kind === 'before'
                  ? billingRule.daysBefore.includes(item.day)
                  : billingRule.daysAfter.includes(item.day);
                return (
                  <button
                    key={`${item.kind}-${item.day}`}
                    type="button"
                    disabled={!billingRule.enabled || savingBillingRule}
                    onClick={() => toggleBillingOffset(item.kind, item.day)}
                    className={`rounded-lg border px-3 py-1.5 text-[12.5px] font-medium transition-colors ${
                      selected
                        ? 'border-[#2456C9] bg-[#EEF4FF] text-[#1D4ED8]'
                        : 'border-[#E4E7EC] bg-white text-[#4A5364] hover:bg-[#F8FAFC]'
                    } disabled:opacity-50`}
                  >
                    {item.label}
                  </button>
                );
              })}
            </div>
            <Button
              variant="outline"
              size="sm"
              onClick={() => void handleSaveBillingRule()}
              disabled={savingBillingRule}
              className="gap-1.5"
            >
              {savingBillingRule && <Loader2 className="h-3.5 w-3.5 animate-spin" />}
              Salvar régua automática
            </Button>
          </CardContent>
        </Card>
      )}
    </div>
  );
}
