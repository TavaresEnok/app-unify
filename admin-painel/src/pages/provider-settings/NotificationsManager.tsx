import { useState } from 'react';
import { useSettings } from '@/contexts/SettingsContext';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Switch } from '@/components/ui/switch';
import { Badge } from '@/components/ui/badge';
import { toast } from 'sonner';
import { Bell, Plus, Send, Trash2, Users, Filter } from 'lucide-react';

export default function NotificationsManager() {
  const { config, setConfig, saveConfig, isSaving } = useSettings();
  const [notifications, setNotifications] = useState(config.notifications?.list || []);
  const [newNotif, setNewNotif] = useState({ title: '', message: '', category: 'info', targetAll: true });
  const [filter, setFilter] = useState('all');

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
    toast.success('Notificação criada!');
  };

  const deleteNotification = (id: string) => {
    if (confirm('Deletar notificação?')) {
      setNotifications(notifications.filter((n: any) => n.id !== id));
      toast.success('Deletada!');
    }
  };

  const sendToAll = () => {
    toast.success(`Enviando ${notifications.filter((n: any) => !n.read).length} notificações para todos os clientes!`);
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
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-3xl font-bold flex items-center gap-2">
            <Bell className="h-8 w-8" />
            Gerenciador de Notificações
          </h2>
          <p className="text-muted-foreground">Envie avisos e promoções para seus clientes</p>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={sendToAll}>
            <Send className="h-4 w-4 mr-2" />
            Enviar Todas
          </Button>
          <Button onClick={handleSave} disabled={isSaving}>
            {isSaving ? 'Salvando...' : 'Salvar Alterações'}
          </Button>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card>
          <CardHeader>
            <CardTitle>Nova Notificação</CardTitle>
            <CardDescription>Crie um aviso para enviar aos clientes</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
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
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <div className="flex items-center justify-between">
              <CardTitle>Notificações Ativas ({filteredNotifications.length})</CardTitle>
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
          </CardHeader>
          <CardContent>
            <div className="space-y-3 max-h-[600px] overflow-auto">
              {filteredNotifications.length === 0 ? (
                <div className="text-center py-12">
                  <Bell className="h-12 w-12 mx-auto text-muted-foreground opacity-20 mb-4" />
                  <p className="text-muted-foreground">Nenhuma notificação</p>
                </div>
              ) : (
                filteredNotifications.map((notif: any) => {
                  const cat = categories.find((c) => c.value === notif.category);
                  return (
                    <div key={notif.id} className="p-4 border rounded-lg space-y-2 hover:bg-accent transition-colors">
                      <div className="flex items-start justify-between">
                        <div className="flex-1">
                          <div className="flex items-center gap-2 mb-1">
                            <p className="font-semibold">{notif.title}</p>
                            <Badge variant={cat?.color as any}>{cat?.label}</Badge>
                            {!notif.dismissible && <Badge variant="outline">Não dispensável</Badge>}
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
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
