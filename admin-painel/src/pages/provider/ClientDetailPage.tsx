import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { useSettings } from '@/contexts/SettingsContext';
import { toast } from 'sonner';
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Loader2, ArrowLeft, UserCircle, AlertTriangle, CreditCard, FileText, Router, Trash2, Send } from 'lucide-react';
import StatusBadge from '@/components/StatusBadge';
import { getErrorMessage } from '@/shared/errors';
import {
  deleteProviderClient,
  fetchProviderClientDetail,
  type ProviderClientItem,
} from '@/shared/api/clients';

export default function ClientDetailPage() {
  const { clientId: identifier } = useParams<{ clientId: string }>();
  const navigate = useNavigate();
  const { user, userRole, providerId: authProviderId } = useAuth();
  const { providerId: settingsProviderId } = useSettings();
  const providerId = settingsProviderId || authProviderId;

  const [client, setClient] = useState<ProviderClientItem | null>(null);
  const [isLoadingClient, setIsLoadingClient] = useState(true);
  const [deleting, setDeleting] = useState(false);

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
    </div>
  );
}
