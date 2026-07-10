import { useState } from 'react';
import { useSettings } from '@/contexts/SettingsContext';
import { useAuth } from '@/contexts/AuthContext';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Switch } from '@/components/ui/switch';
import { toast } from 'sonner';
import { Bell, Plus, Send, Trash2, Users } from 'lucide-react';
import { db } from '@/firebase/config';
import { doc, setDoc, collection, onSnapshot, serverTimestamp } from 'firebase/firestore';
import { SettingsPage, SettingsSection } from '@/components/settings/SettingsPage';
import StatusBadge from '@/components/StatusBadge';

export default function NotificationsManager() {
  const { config, setConfig, saveConfig, isSaving, providerId } = useSettings();
  const { user } = useAuth();
  const [notifications, setNotifications] = useState(config.notifications?.list || []);
  const [newNotif, setNewNotif] = useState({ title: '', message: '', category: 'info', targetAll: true });
  const [filter, setFilter] = useState('all');
  const [isSending, setIsSending] = useState(false);

  const categories = [
    { value: 'urgent', label: 'Urgente', color: 'destructive' },
    { value: 'info', label: 'Informação', color: 'default' },
    { value: 'promo', label: 'Promoção', color: 'secondary' },
  ];

  const createNotification = () => {
    if (!newNotif.title || !newNotif.message) {
      toast.error('Preencha título e mensagem');
      return;
    }
    const notif = {
      id: `notif_${Date.now()}`,
      ...newNotif,
      createdAt: new Date().toISOString(),
      read: false,
      dismissible: newNotif.category !== 'urgent',
    };
    setNotifications([notif, ...notifications]);
    setNewNotif({ title: '', message: '', category: 'info', targetAll: true });
    toast.success('Notificação criada! Clique em "Enviar Push" para entregar aos clientes.');
  };

  const deleteNotification = (id: string) => {
    if (confirm('Deletar notificação?')) {
      setNotifications(notifications.filter((n: any) => n.id !== id));
      toast.success('Deletada!');
    }
  };

  // NOVA FUNÇÃO: Enviar Push Real via Cloud Function
  const sendPushNotification = async (notif: any) => {
    if (!user) {
      toast.error('Usuário não autenticado');
      return;
    }

    setIsSending(true);
    const toastId = toast.loading('Enviando notificação push...');

    try {
      const requestId = doc(collection(db, 'function_requests')).id;
      const responseDocRef = doc(db, 'function_responses', requestId);

      // Escuta pela resposta
      const unsubscribe = onSnapshot(responseDocRef, (docSnap) => {
        if (docSnap.exists()) {
          unsubscribe();
          const response = docSnap.data();
          if (response.result?.success) {
            toast.success(response.result.message, { id: toastId });
          } else {
            toast.error(`Erro: ${response.error}`, { id: toastId });
          }
          setIsSending(false);
        }
      });

      // Envia request para Cloud Function
      await setDoc(doc(db, 'function_requests', requestId), {
        type: 'SEND_PUSH_NOTIFICATION',
        requesterUid: user.uid,
        createdAt: serverTimestamp(),
        payload: {
          providerId,
          title: notif.title,
          body: notif.message,
          category: notif.category,
          targetAll: notif.targetAll,
          route: notif.route || '',
        }
      });

      // Timeout de 30 segundos
      setTimeout(() => {
        setIsSending(false);
      }, 30000);

    } catch (error: any) {
      toast.error(`Erro: ${error.message}`, { id: toastId });
      setIsSending(false);
    }
  };

  const sendToAll = async () => {
    const pendingNotifs = notifications.filter((n: any) => !n.sent);
    if (pendingNotifs.length === 0) {
      toast.info('Nenhuma notificação pendente para enviar');
      return;
    }

    for (const notif of pendingNotifs) {
      await sendPushNotification(notif);
    }
  };

  const handleSave = async () => {
    setConfig({ ...config, notifications: { ...config.notifications, list: notifications } });
    await saveConfig();
    toast.success('Notificações salvas!');
  };

  const filteredNotifications = filter === 'all'
    ? notifications
    : notifications.filter((n: any) => n.category === filter);

  return (
    <SettingsPage
      title="Notificações"
      description="Envie avisos e promoções para seus clientes."
      icon={Bell}
      actions={(
        <>
          <Button variant="outline" onClick={sendToAll}>
            <Send className="h-4 w-4 mr-2" />
            Enviar Todas
          </Button>
          <Button onClick={handleSave} disabled={isSaving}>
            {isSaving ? 'Salvando...' : 'Salvar Alterações'}
          </Button>
        </>
      )}
    >

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <SettingsSection title="Nova notificação" description="Crie um aviso para enviar aos clientes.">
          <div className="space-y-4">
            <div>
              <Label>Título *</Label>
              <Input
                value={newNotif.title}
                onChange={(e) => setNewNotif({ ...newNotif, title: e.target.value })}
                placeholder="Ex: Manutenção Programada"
                maxLength={100}
              />
              <p className="text-xs text-muted-foreground mt-1">{newNotif.title.length}/100</p>
            </div>

            <div>
              <Label>Mensagem *</Label>
              <Textarea
                value={newNotif.message}
                onChange={(e) => setNewNotif({ ...newNotif, message: e.target.value })}
                placeholder="Digite a mensagem completa..."
                rows={5}
                maxLength={500}
              />
              <p className="text-xs text-muted-foreground mt-1">{newNotif.message.length}/500</p>
            </div>

            <div>
              <Label>Categoria</Label>
              <Select value={newNotif.category} onValueChange={(v) => setNewNotif({ ...newNotif, category: v })}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  {categories.map((cat) => (
                    <SelectItem key={cat.value} value={cat.value}>{cat.label}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="flex items-center justify-between p-4 border rounded-lg">
              <div className="flex items-center gap-2">
                <Users className="h-4 w-4" />
                <Label>Enviar para todos os clientes</Label>
              </div>
              <Switch
                checked={newNotif.targetAll}
                onCheckedChange={(checked) => setNewNotif({ ...newNotif, targetAll: checked })}
              />
            </div>

            <Button onClick={createNotification} className="w-full" size="lg">
              <Plus className="h-4 w-4 mr-2" />
              Criar Notificação
            </Button>
          </div>
        </SettingsSection>

        <SettingsSection>
            <div className="flex items-center justify-between">
              <div>
                <h3 className="text-[13px] font-semibold text-[#1A2233]">Notificações ativas ({filteredNotifications.length})</h3>
                <p className="mt-0.5 text-[12px] text-[#687181]">Filtre, envie ou remova notificações cadastradas.</p>
              </div>
              <Select value={filter} onValueChange={setFilter}>
                <SelectTrigger className="w-32">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">Todas</SelectItem>
                  {categories.map(cat => (
                    <SelectItem key={cat.value} value={cat.value}>{cat.label}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="mt-4 max-h-[600px] space-y-3 overflow-auto">
              {filteredNotifications.length === 0 ? (
                <div className="text-center py-12">
                  <Bell className="h-12 w-12 mx-auto text-muted-foreground opacity-20 mb-4" />
                  <p className="text-muted-foreground">Nenhuma notificação</p>
                </div>
              ) : (
                filteredNotifications.map((notif: any) => {
                  const cat = categories.find((c) => c.value === notif.category);
                  return (
                    <div key={notif.id} className="space-y-2 rounded-lg border border-[#EEF0F4] bg-white p-4 transition-colors hover:bg-[#F8FAFC]">
                      <div className="flex items-start justify-between">
                        <div className="flex-1">
                          <div className="flex items-center gap-2 mb-1">
                            <p className="font-semibold">{notif.title}</p>
                            <StatusBadge status={cat?.label || notif.category} tone={notif.category === 'urgent' ? 'red' : notif.category === 'promo' ? 'amber' : 'blue'} />
                            {!notif.dismissible && <StatusBadge status="Não dispensável" tone="gray" />}
                          </div>
                          <p className="text-sm text-muted-foreground line-clamp-2">{notif.message}</p>
                          <div className="flex items-center gap-4 mt-2 text-xs text-muted-foreground">
                            <span>{new Date(notif.createdAt).toLocaleString('pt-BR')}</span>
                            {notif.targetAll && (
                              <span className="flex items-center gap-1">
                                <Users className="h-3 w-3" />
                                Todos
                              </span>
                            )}
                          </div>
                        </div>
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => deleteNotification(notif.id)}
                        >
                          <Trash2 className="h-4 w-4 text-destructive" />
                        </Button>
                      </div>
                    </div>
                  );
                })
              )}
            </div>
        </SettingsSection>
      </div>
    </SettingsPage>
  );
}
