import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { useSettings } from '@/contexts/SettingsContext';
import { toast } from 'sonner';
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Loader2, ArrowLeft, UserCircle, AlertTriangle, CreditCard, FileText, Router, Trash2, Send, RefreshCw, Power, Sparkles, Activity, Wifi, Laptop } from 'lucide-react';
import StatusBadge from '@/components/StatusBadge';
import { getErrorMessage } from '@/shared/errors';
import {
  deleteProviderClient,
  fetchProviderClientDetail,
  type ProviderClientItem,
} from '@/shared/api/clients';
import {
  fetchAdminClientCpeOverview,
  optimizeAdminClientWifi,
  rebootAdminClientCpe,
  runAdminClientCpeDiagnostic,
  type AdminCpeOverviewResponse,
  type CpeDiagnosticResult,
} from '@/shared/api/tr069';

export default function ClientDetailPage() {
  const { clientId: identifier } = useParams<{ clientId: string }>();
  const navigate = useNavigate();
  const { user, userRole, providerId: authProviderId } = useAuth();
  const { providerId: settingsProviderId } = useSettings();
  const providerId = settingsProviderId || authProviderId;

  const [client, setClient] = useState<ProviderClientItem | null>(null);
  const [isLoadingClient, setIsLoadingClient] = useState(true);
  const [deleting, setDeleting] = useState(false);

  // TR-069 / CPE management
  const [cpeData, setCpeData] = useState<AdminCpeOverviewResponse | null>(null);
  const [cpeLoading, setCpeLoading] = useState(false);
  const [cpeError, setCpeError] = useState<string | null>(null);
  const [cpeBusyAction, setCpeBusyAction] = useState<string | null>(null);
  const [cpeDiag, setCpeDiag] = useState<CpeDiagnosticResult | null>(null);

  const loadCpeOverview = async (targetId: string) => {
    if (!providerId) return;
    setCpeLoading(true);
    setCpeError(null);
    try {
      const data = await fetchAdminClientCpeOverview(providerId, targetId);
      setCpeData(data);
    } catch (error) {
      setCpeError(getErrorMessage(error, 'Não foi possível consultar o roteador TR-069.'));
    } finally {
      setCpeLoading(false);
    }
  };

  const handleCpeReboot = async () => {
    if (!providerId || !client) return;
    if (!window.confirm(`Reiniciar remotamente o roteador de ${client.nome}? A conexão cairá por ~2 minutos.`)) return;
    setCpeBusyAction('reboot');
    try {
      const res = await rebootAdminClientCpe(providerId, client.cpfcnpj || client.id);
      toast.success(res.message);
    } catch (error) {
      toast.error(getErrorMessage(error, 'Falha ao reiniciar roteador.'));
    } finally {
      setCpeBusyAction(null);
    }
  };

  const handleCpeOptimize = async () => {
    if (!providerId || !client) return;
    setCpeBusyAction('optimize');
    try {
      const res = await optimizeAdminClientWifi(providerId, client.cpfcnpj || client.id);
      toast.success(res.message);
    } catch (error) {
      toast.error(getErrorMessage(error, 'Falha ao otimizar canal Wi-Fi.'));
    } finally {
      setCpeBusyAction(null);
    }
  };

  const handleCpeDiag = async () => {
    if (!providerId || !client) return;
    setCpeBusyAction('diag');
    try {
      const result = await runAdminClientCpeDiagnostic(providerId, client.cpfcnpj || client.id);
      setCpeDiag(result);
      toast.success('Diagnóstico TR-143 executado no roteador.');
    } catch (error) {
      toast.error(getErrorMessage(error, 'Falha ao executar diagnóstico no roteador.'));
    } finally {
      setCpeBusyAction(null);
    }
  };

  useEffect(() => {
    if (!identifier || !providerId || !user) {
      setIsLoadingClient(false);
      return;
    }
    let cancelled = false;
    setIsLoadingClient(true);
    fetchProviderClientDetail(providerId, identifier)
      .then((data) => {
        if (!cancelled) setClient(data);
      })
      .catch((error) => {
        if (!cancelled) {
          toast.error(getErrorMessage(error, 'Falha ao carregar detalhes do cliente.'));
          setClient(null);
        }
      })
      .finally(() => {
        if (!cancelled) setIsLoadingClient(false);
      });
    return () => { cancelled = true; };
  }, [identifier, providerId, user]);

  const handleDeleteClient = async () => {
    if (!client || !providerId) return;
    if (!window.confirm(`Remover ${client.nome} do cache local e push? Isso não apaga o cliente no SGP.`)) {
      return;
    }
    setDeleting(true);
    try {
      const res = await deleteProviderClient(providerId, client.cpfcnpj || client.id);
      toast.success('Cliente removido', { description: res.message });
      navigate('/provedor/clientes');
    } catch (error) {
      toast.error(getErrorMessage(error, 'Não foi possível remover o cliente.'));
    } finally {
      setDeleting(false);
    }
  };

  if (isLoadingClient) {
    return <div className="flex justify-center items-center h-full"><Loader2 className="animate-spin" /></div>;
  }

  if (!client) {
    return (
      <Card>
        <CardHeader><CardTitle>Cliente não encontrado</CardTitle></CardHeader>
        <CardContent className="flex flex-col items-center gap-4 py-8">
          <AlertTriangle className="h-12 w-12 text-destructive" />
          <p className="text-sm text-muted-foreground">
            O identificador <span className="font-mono">{identifier}</span> não foi encontrado no banco local.
          </p>
          <Button onClick={() => navigate(-1)}>Voltar</Button>
        </CardContent>
      </Card>
    );
  }

  const isSuperAdmin = userRole === 'superAdmin';
  const show = (value?: string | null) => (value && value.trim() ? value : '-');

  return (
    <div className="space-y-5">
      <div className="flex flex-col justify-between gap-3 sm:flex-row sm:items-center">
        <Button variant="outline" onClick={() => navigate(-1)} className="gap-2 w-fit">
          <ArrowLeft className="h-4 w-4" /> Voltar
        </Button>
        <div className="flex flex-wrap gap-2">
          <Button
            variant="outline"
            className="gap-2"
            onClick={() => navigate(
              isSuperAdmin ? `/provedores/${providerId}/comunicados/notificacoes` : '/provedor/comunicados/notificacoes',
              { state: { targetCpf: client.cpfcnpj } },
            )}
          >
            <Send className="h-4 w-4" />
            Enviar push
          </Button>
          <Button variant="destructive" onClick={() => void handleDeleteClient()} disabled={deleting} className="gap-2">
            {deleting ? <Loader2 className="h-4 w-4 animate-spin" /> : <Trash2 className="h-4 w-4" />}
            Apagar do cache
          </Button>
        </div>
      </div>

      <Card className="overflow-hidden">
        <CardHeader className="border-b border-[#EEF0F4]">
          <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
            <div className="flex min-w-0 items-center gap-3">
              <span className="grid h-12 w-12 shrink-0 place-items-center rounded-xl bg-[#0E1320] text-white">
                <UserCircle className="h-6 w-6" />
              </span>
              <div className="min-w-0">
                <CardTitle className="truncate text-[20px] leading-6">{client.nome}</CardTitle>
                <div className="mt-2 flex flex-wrap items-center gap-2">
                  <span className="rounded-full bg-[#EEF0F4] px-2.5 py-0.5 font-mono text-[11px] font-semibold text-[#5B6472]">
                    {client.cpfcnpj}
                  </span>
                  <StatusBadge status={client.status || 'Ativo'} />
                  <StatusBadge
                    status={client.hasAppDevice ? 'Push ativo no app' : 'Sem token push'}
                    tone={client.hasAppDevice ? 'green' : 'gray'}
                  />
                  {client.cidade && (
                    <span className="text-[12.5px] text-[#687181]">
                      {[client.cidade, client.bairro].filter(Boolean).join(' · ')}
                    </span>
                  )}
                </div>
              </div>
            </div>
            <div className="text-left sm:text-right">
              <p className="text-[11.5px] font-semibold uppercase tracking-[0.06em] text-[#98A1B1]">ID SGP</p>
              <p className="font-mono text-[13px] font-semibold text-[#1A2233]">{client.id}</p>
            </div>
          </div>
        </CardHeader>
      </Card>

      <div className="grid gap-4 lg:grid-cols-3">
        <Card>
          <CardHeader className="flex-row items-center gap-2 space-y-0 border-b border-[#EEF0F4]">
            <FileText className="h-4 w-4 text-[#98A1B1]" />
            <CardTitle>Contrato</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4 p-[18px] text-[12.5px]">
            <div>
              <p className="mb-1 text-[#98A1B1]">Plano</p>
              <p className="font-semibold text-[#1A2233]">{show(client.plano)}</p>
            </div>
            <div>
              <p className="mb-1 text-[#98A1B1]">Contrato(s)</p>
              <p className="font-mono text-[12px] text-[#4A5364]">
                {client.contratoIds.length ? client.contratoIds.join(', ') : '-'}
              </p>
            </div>
            <div>
              <p className="mb-1 text-[#98A1B1]">Provedor</p>
              <p className="font-semibold text-[#1A2233]">{providerId}</p>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex-row items-center gap-2 space-y-0 border-b border-[#EEF0F4]">
            <Router className="h-4 w-4 text-[#98A1B1]" />
            <CardTitle>Rede Óptica e Endereço</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4 p-[18px] text-[12.5px]">
            <div>
              <p className="mb-1 text-[#98A1B1]">Endereço</p>
              <p className="font-semibold text-[#1A2233]">{show(client.endereco)}</p>
            </div>
            <div>
              <p className="mb-1 text-[#98A1B1]">OLT / Porta PON</p>
              <p className="font-mono text-[12px] text-[#4A5364]">
                {[client.oltName, client.pon].filter(Boolean).join(' · ') || '-'}
              </p>
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <p className="mb-1 text-[#98A1B1]">CTO / Caixa</p>
                <p className="font-mono text-[12px] text-[#4A5364]">{show(client.cto)}</p>
              </div>
              <div>
                <p className="mb-1 text-[#98A1B1]">Login PPPoE</p>
                <p className="font-mono text-[12px] text-[#4A5364] truncate">{show(client.login)}</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex-row items-center gap-2 space-y-0 border-b border-[#EEF0F4]">
            <CreditCard className="h-4 w-4 text-[#98A1B1]" />
            <CardTitle>Situação</CardTitle>
          </CardHeader>
          <CardContent className="space-y-4 p-[18px] text-[12.5px]">
            <div>
              <p className="mb-1 text-[#98A1B1]">Status do contrato</p>
              <StatusBadge status={client.status || 'Ativo'} />
            </div>
            <div>
              <p className="mb-1 text-[#98A1B1]">Vencimento</p>
              <p className="font-mono text-[12px] text-[#4A5364]">{show(client.vencimento)}</p>
            </div>
            <div>
              <p className="mb-1 text-[#98A1B1]">Documento</p>
              <p className="font-mono text-[12px] text-[#4A5364]">{client.cpfcnpj}</p>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Gestão Remota do Roteador / CPE (TR-069 / ACS) */}
      <Card>
        <CardHeader className="flex flex-row flex-wrap items-center justify-between gap-2 border-b border-[#EEF0F4]">
          <div className="flex items-center gap-2">
            <Wifi className="h-4 w-4 text-[#2456C9]" />
            <div>
              <CardTitle>Roteador / CPE (TR-069)</CardTitle>
              <p className="text-[12px] text-[#687181]">
                Diagnóstico remoto, portas LAN, dispositivos Wi-Fi e ações N1 direto no equipamento do assinante.
              </p>
            </div>
          </div>
          <div className="flex flex-wrap gap-2">
            <Button
              size="sm"
              variant="outline"
              disabled={cpeLoading}
              onClick={() => void loadCpeOverview(client.cpfcnpj || client.id)}
              className="gap-1.5"
            >
              {cpeLoading ? <Loader2 className="h-3.5 w-3.5 animate-spin" /> : <RefreshCw className="h-3.5 w-3.5" />}
              {cpeData ? 'Atualizar CPE' : 'Consultar CPE'}
            </Button>
            {cpeData?.enabled && cpeData.overview && (
              <>
                <Button size="sm" variant="outline" disabled={cpeBusyAction !== null} onClick={() => void handleCpeOptimize()} className="gap-1.5">
                  {cpeBusyAction === 'optimize' ? <Loader2 className="h-3.5 w-3.5 animate-spin" /> : <Sparkles className="h-3.5 w-3.5" />}
                  Otimizar canal
                </Button>
                <Button size="sm" variant="outline" disabled={cpeBusyAction !== null} onClick={() => void handleCpeDiag()} className="gap-1.5">
                  {cpeBusyAction === 'diag' ? <Loader2 className="h-3.5 w-3.5 animate-spin" /> : <Activity className="h-3.5 w-3.5" />}
                  Testar no roteador
                </Button>
                <Button size="sm" variant="destructive" disabled={cpeBusyAction !== null} onClick={() => void handleCpeReboot()} className="gap-1.5">
                  {cpeBusyAction === 'reboot' ? <Loader2 className="h-3.5 w-3.5 animate-spin" /> : <Power className="h-3.5 w-3.5" />}
                  Reiniciar CPE
                </Button>
              </>
            )}
          </div>
        </CardHeader>
        <CardContent className="p-[18px] text-[12.5px]">
          {!cpeData && !cpeLoading && !cpeError && (
            <p className="text-[#687181]">Clique em <strong>Consultar CPE</strong> para ler o roteador deste cliente via TR-069/ACS.</p>
          )}
          {cpeError && <p className="text-destructive">{cpeError}</p>}
          {cpeData && !cpeData.enabled && (
            <p className="text-[#687181]">Integração TR-069/ACS não ativada para este provedor. Configure em <em>Configurações → Integrações</em>.</p>
          )}
          {cpeData?.enabled && cpeData.overview && (
            <div className="space-y-4">
              {cpeData.overview.lanBottleneck100Mbps && (
                <div className="flex items-center gap-2 rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-red-800">
                  <AlertTriangle className="h-4 w-4 shrink-0" />
                  <span>
                    <strong>Gargalo físico detectado:</strong> há porta LAN negociando em 100 Mbps em um plano de {cpeData.overview.planDownloadMbps} Mbps. Verifique cabo/conector RJ45.
                  </span>
                </div>
              )}

              <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-4">
                <div className="rounded-lg border border-[#EEF0F4] p-3">
                  <p className="text-[11px] text-[#98A1B1]">Status / Driver</p>
                  <div className="mt-1 flex items-center gap-1.5">
                    <StatusBadge status={cpeData.overview.online ? 'Online' : 'Offline'} tone={cpeData.overview.online ? 'green' : 'red'} />
                    <span className="font-mono text-[11px] uppercase text-[#687181]">{cpeData.driver}</span>
                  </div>
                </div>
                <div className="rounded-lg border border-[#EEF0F4] p-3">
                  <p className="text-[11px] text-[#98A1B1]">Modelo / Firmware</p>
                  <p className="mt-1 font-semibold text-[#1A2233] truncate">{[cpeData.overview.manufacturer, cpeData.overview.model].filter(Boolean).join(' ') || '-'}</p>
                  <p className="font-mono text-[11px] text-[#687181] truncate">{cpeData.overview.firmware || '-'}</p>
                </div>
                <div className="rounded-lg border border-[#EEF0F4] p-3">
                  <p className="text-[11px] text-[#98A1B1]">Serial / IP WAN</p>
                  <p className="mt-1 font-mono text-[12px] text-[#1A2233] truncate">{cpeData.overview.serial || '-'}</p>
                  <p className="font-mono text-[11px] text-[#687181]">{cpeData.overview.wanIp || '-'}</p>
                </div>
                <div className="rounded-lg border border-[#EEF0F4] p-3">
                  <p className="text-[11px] text-[#98A1B1]">Uptime / Sinal Óptico</p>
                  <p className="mt-1 font-mono text-[12px] text-[#1A2233]">
                    {cpeData.overview.uptimeSeconds != null ? `${Math.floor(cpeData.overview.uptimeSeconds / 3600)}h` : '-'}
                  </p>
                  <p className="font-mono text-[11px] text-[#687181]">
                    {cpeData.overview.opticalRxDbm != null ? `${cpeData.overview.opticalRxDbm} dBm` : 'RX indisponível'}
                  </p>
                </div>
              </div>

              {cpeDiag && (
                <div className="rounded-lg border border-blue-200 bg-blue-50/60 p-3 text-[#1A2233]">
                  <div className="font-semibold">Resultado TR-143 (executado no roteador)</div>
                  <p className="mt-0.5 text-[12px] text-[#4A5364]">{cpeDiag.summary}</p>
                </div>
              )}

              {cpeData.overview.wifiNetworks.length > 0 && (
                <div>
                  <p className="mb-2 text-[12px] font-semibold text-[#1A2233]">Redes Wi-Fi ({cpeData.overview.wifiNetworks.length})</p>
                  <div className="grid gap-2 sm:grid-cols-2">
                    {cpeData.overview.wifiNetworks.map((w) => (
                      <div key={w.id} className="flex items-center justify-between rounded-lg border border-[#EEF0F4] px-3 py-2">
                        <div className="min-w-0">
                          <span className="font-semibold text-[#1A2233]">{w.ssid}</span>
                          <span className="ml-2 font-mono text-[11px] text-[#687181]">{w.band} · Canal {w.channel}</span>
                        </div>
                        <div className="flex items-center gap-1.5">
                          {w.isGuest && <StatusBadge status="Visitante" tone="blue" />}
                          <StatusBadge status={w.enabled ? 'Ativa' : 'Desligada'} tone={w.enabled ? 'green' : 'gray'} />
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {cpeData.hosts.length > 0 && (
                <div>
                  <p className="mb-2 flex items-center gap-1.5 text-[12px] font-semibold text-[#1A2233]">
                    <Laptop className="h-3.5 w-3.5" /> Dispositivos conectados ({cpeData.hosts.length})
                  </p>
                  <div className="divide-y divide-[#F2F4F7] rounded-lg border border-[#EEF0F4]">
                    {cpeData.hosts.map((h) => (
                      <div key={`${h.mac}-${h.ip}`} className="flex flex-wrap items-center justify-between gap-2 px-3 py-2">
                        <div className="min-w-0">
                          <span className="font-semibold text-[#1A2233]">{h.hostname}</span>
                          <span className="ml-2 font-mono text-[11px] text-[#98A1B1]">{h.ip} · {h.mac}</span>
                        </div>
                        <div className="flex items-center gap-2">
                          <span className="rounded bg-[#F2F4F7] px-2 py-0.5 font-mono text-[11px] text-[#4A5364]">
                            {h.interfaceType === 'ethernet' ? 'Cabo' : h.interfaceType === 'wifi_5g' ? 'Wi-Fi 5G' : h.interfaceType === 'wifi_2g' ? 'Wi-Fi 2.4G' : 'Rede'}
                          </span>
                          {h.rssiDbm != null && (
                            <StatusBadge
                              status={`${h.rssiDbm} dBm`}
                              tone={h.signalQuality === 'weak' ? 'red' : h.signalQuality === 'fair' ? 'amber' : 'green'}
                            />
                          )}
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
