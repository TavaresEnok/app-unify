import { useState, useEffect, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { useSettings } from '@/contexts/SettingsContext';
import { toast } from 'sonner';
import { Loader2, UserX, Search, RefreshCw, ChevronRight, Smartphone } from 'lucide-react';
import EmptyState from '@/components/EmptyState';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import DataTable from '@/components/DataTable';
import StatusBadge from '@/components/StatusBadge';
import {
  fetchProviderClients,
  getProviderClientsSyncStatus,
  triggerProviderClientsSync,
  type ClientAppFilter,
  type ProviderClientItem,
} from '@/shared/api/clients';

const ITEMS_PER_PAGE = 25;

function useDebounce(value: string, delay: number) {
  const [debouncedValue, setDebouncedValue] = useState(value);
  useEffect(() => {
    const handler = setTimeout(() => setDebouncedValue(value), delay);
    return () => clearTimeout(handler);
  }, [value, delay]);
  return debouncedValue;
}

export default function ProviderClientsPage() {
  const navigate = useNavigate();
  const { user, userRole, providerId: authProviderId } = useAuth();
  const { providerId: settingsProviderId } = useSettings();
  const providerId = settingsProviderId || authProviderId;
  const clientsBasePath = userRole === 'superAdmin' && providerId
    ? `/provedores/${encodeURIComponent(providerId)}/clientes`
    : '/provedor/clientes';

  const [clients, setClients] = useState<ProviderClientItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [isSyncing, setIsSyncing] = useState(false);
  const [syncProgress, setSyncProgress] = useState<number | null>(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [appFilter, setAppFilter] = useState<ClientAppFilter>('all');
  const [currentPage, setCurrentPage] = useState(1);
  const [totalClients, setTotalClients] = useState(0);
  const [appUsersCount, setAppUsersCount] = useState(0);
  const [lastSyncedAt, setLastSyncedAt] = useState<string | null>(null);
  const [syncJobId, setSyncJobId] = useState<string | null>(null);

  const debouncedSearchTerm = useDebounce(searchTerm, 300);
  const pageCount = Math.max(1, Math.ceil(totalClients / ITEMS_PER_PAGE));

  const loadClients = useCallback(async (page: number, search: string, filter: ClientAppFilter) => {
    if (!providerId || !user) return;
    setLoading(true);
    try {
      const data = await fetchProviderClients(providerId, {
        page,
        limit: ITEMS_PER_PAGE,
        search,
        appFilter: filter,
      });
      setClients(data.clientes);
      setTotalClients(data.total);
      setAppUsersCount(data.appUsersCount ?? 0);
      setLastSyncedAt(data.lastSyncedAt);
    } catch (error) {
      toast.error('Falha ao carregar clientes', {
        description: error instanceof Error ? error.message : 'Tente novamente.',
      });
    } finally {
      setLoading(false);
    }
  }, [providerId, user]);

  useEffect(() => {
    if (!isSyncing) {
      void loadClients(currentPage, debouncedSearchTerm, appFilter);
    }
  }, [currentPage, debouncedSearchTerm, appFilter, loadClients, isSyncing]);

  const handleStartSync = async () => {
    if (!providerId || !user) return;
    setIsSyncing(true);
    setSyncProgress(0);
    try {
      const res = await triggerProviderClientsSync(providerId);
      setSyncJobId(String(res.jobId));
      toast.info('Sincronização iniciada em segundo plano. Aguarde a conclusão.');
    } catch (error) {
      setIsSyncing(false);
      setSyncProgress(null);
      toast.error('Não foi possível iniciar a sincronização', {
        description: error instanceof Error ? error.message : 'Tente novamente.',
      });
    }
  };

  useEffect(() => {
    if (!syncJobId || !providerId) return;
    let stopped = false;
    let timer: ReturnType<typeof setTimeout>;
    const poll = async () => {
      try {
        const result = await getProviderClientsSyncStatus(providerId, syncJobId);
        if (stopped) return;
        if (typeof result.progress?.count === 'number') {
          setSyncProgress(result.progress.count);
        }
        if (result.status === 'completed' || result.status === 'failed') {
          setSyncJobId(null);
          setIsSyncing(false);
          setSyncProgress(null);
          setCurrentPage(1);
          if (result.status === 'completed') {
            toast.success(`Sincronização concluída (${result.count ?? 0} clientes atualizados).`);
            void loadClients(1, debouncedSearchTerm, appFilter);
          } else {
            toast.error('A sincronização falhou. Tente novamente.');
          }
          return;
        }
      } catch {
        // Uma interrupção de rede não cancela o trabalho no servidor.
      }
      if (!stopped) timer = setTimeout(poll, 4000);
    };
    void poll();
    return () => { stopped = true; clearTimeout(timer); };
  }, [syncJobId, providerId, loadClients, debouncedSearchTerm, appFilter]);

  const handleSearchChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    setSearchTerm(event.target.value);
    setCurrentPage(1);
  };

  const formattedLastSync = lastSyncedAt
    ? new Date(lastSyncedAt).toLocaleString('pt-BR', { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' })
    : null;

  if (loading && clients.length === 0) {
    return (
      <div className="flex flex-col justify-center items-center h-full text-center">
        <Loader2 className="animate-spin h-8 w-8 mb-4" />
        <p className="text-lg font-semibold">Carregando clientes...</p>
      </div>
    );
  }

  return (
    <DataTable<ProviderClientItem>
      title="Clientes"
      description={
        totalClients > 0
          ? `${totalClients} cliente(s) exibido(s) · ${appUsersCount} com app ativo${formattedLastSync ? ` · atualizado em ${formattedLastSync}` : ''}.`
          : appFilter !== 'all'
            ? 'Nenhum cliente corresponde ao filtro selecionado.'
            : 'Nenhum cliente sincronizado ainda.'
      }
      actions={(
        <>
          <div className="flex items-center rounded-lg border border-[#E4E7EC] bg-[#F8FAFC] p-0.5">
            {([
              { id: 'all', label: 'Todos' },
              { id: 'with_app', label: 'Com app' },
              { id: 'without_app', label: 'Sem app' },
            ] as const).map((opt) => (
              <button
                key={opt.id}
                type="button"
                onClick={() => { setAppFilter(opt.id); setCurrentPage(1); }}
                className={`rounded-md px-2.5 py-1 text-[12px] font-medium transition-colors ${
                  appFilter === opt.id ? 'bg-white text-[#1A2233] shadow-sm' : 'text-[#687181] hover:text-[#1A2233]'
                }`}
              >
                {opt.label}
              </button>
            ))}
          </div>
          <div className="relative flex-grow sm:flex-grow-0 sm:w-64">
            <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
            <Input
              type="search"
              placeholder="Buscar nome, CPF, cidade, bairro ou OLT..."
              className="pl-8 w-full"
              value={searchTerm}
              onChange={handleSearchChange}
            />
          </div>
          <Button onClick={() => void handleStartSync()} disabled={isSyncing} variant="outline">
            {isSyncing ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <RefreshCw className="mr-2 h-4 w-4" />}
            {isSyncing ? (syncProgress ? `Sincronizando (${syncProgress})…` : 'Sincronizando…') : 'Sincronizar'}
          </Button>
        </>
      )}
      columns={[
        { label: 'Cliente' },
        { label: 'Contrato / Plano' },
        { label: 'CPF/CNPJ' },
        { label: 'Status' },
        { label: 'Cidade / OLT' },
        { label: '' },
      ]}
      gridTemplate="2fr 1.2fr 1.1fr .8fr 1.3fr 32px"
      rows={!loading ? clients : []}
      getRowKey={(client) => `${client.id}-${client.cpfcnpj}`}
      minWidth="880px"
      empty={loading ? (
        <div className="flex h-64 items-center justify-center"><Loader2 className="h-8 w-8 animate-spin" /></div>
      ) : (
        <EmptyState
          icon={UserX}
          title={searchTerm ? 'Nenhum resultado para sua busca' : 'Nenhum cliente sincronizado'}
          description={searchTerm
            ? `Não encontramos clientes para "${searchTerm}". Limpe a busca para ver todos.`
            : 'Clique em "Sincronizar" para importar sua base de clientes.'}
        />
      )}
      renderRow={(client) => (
        <button
          type="button"
          className="grid w-full items-center gap-x-3 border-b border-[#F2F4F7] px-[18px] py-[11px] text-left transition-colors hover:bg-[#F8FAFC]"
          style={{ gridTemplateColumns: '2fr 1.2fr 1.1fr .8fr 1.3fr 32px' }}
          onClick={() => navigate(`${clientsBasePath}/${encodeURIComponent(client.cpfcnpj || client.id)}`)}
        >
          <span className="min-w-0">
            <span className="flex items-center gap-1.5">
              <span className="truncate text-[13px] font-semibold text-[#1A2233]">{client.nome}</span>
              {client.hasAppDevice && (
                <span className="inline-flex shrink-0 items-center gap-0.5 rounded bg-emerald-50 px-1.5 py-0.5 text-[10px] font-semibold text-emerald-700">
                  <Smartphone className="h-2.5 w-2.5" /> App
                </span>
              )}
            </span>
            <span className="block font-mono text-[10.5px] text-[#98A1B1]">ID {client.id}</span>
          </span>
          <span className="min-w-0">
            <span className="block truncate text-[12px] font-medium text-[#2F3748]">{client.plano || '-'}</span>
            <span className="block truncate font-mono text-[10.5px] text-[#98A1B1]">
              {client.contratoIds.length ? `#${client.contratoIds.join(', #')}` : '-'}
            </span>
          </span>
          <span className="truncate font-mono text-[12px] text-[#4A5364]">{client.cpfcnpj}</span>
          <StatusBadge status={client.status || 'Ativo'} />
          <span className="min-w-0">
            <span className="block truncate text-[12px] text-[#4A5364]">
              {[client.cidade, client.bairro].filter(Boolean).join(' · ') || '-'}
            </span>
            {client.oltName && (
              <span className="block truncate font-mono text-[10.5px] text-[#7D8798]">{client.oltName}</span>
            )}
          </span>
          <ChevronRight className="h-3.5 w-3.5 justify-self-end text-[#B9C0CC]" />
        </button>
      )}
      footer={totalClients > ITEMS_PER_PAGE && (
        <div className="flex items-center justify-between">
          <span className="text-[12px] text-[#98A1B1]">
            Página {currentPage} de {pageCount}
          </span>
          <div className="flex items-center gap-2">
            <Button
              variant="outline"
              size="sm"
              onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
              disabled={currentPage <= 1 || loading}
            >
              Anterior
            </Button>
            <Button
              variant="outline"
              size="sm"
              onClick={() => setCurrentPage((p) => Math.min(pageCount, p + 1))}
              disabled={currentPage >= pageCount || loading}
            >
              Próxima
            </Button>
          </div>
        </div>
      )}
    />
  );
}
