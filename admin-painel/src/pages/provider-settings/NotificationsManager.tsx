import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useSettings } from '@/contexts/SettingsContext';
import { useAuth } from '@/contexts/AuthContext';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { toast } from 'sonner';
import { Bell, Plus, Trash2 } from 'lucide-react';
import { SettingsPage, SettingsSection } from '@/components/settings/SettingsPage';
import StatusBadge from '@/components/StatusBadge';

interface NotificationTemplate {
  id: string; title: string; message: string; category: string; createdAt: string;
  [key: string]: unknown;
}

export default function NotificationsManager() {
  const { config, setConfig, saveConfig, isSaving, providerId } = useSettings();
  const { userRole } = useAuth();
  const navigate = useNavigate();
  const [draft, setDraft] = useState({ title: '', message: '', category: 'info' });
  const templates: NotificationTemplate[] = config.notifications?.list || [];
  const categories = [{ value: 'urgent', label: 'Urgente' }, { value: 'info', label: 'Informação' }, { value: 'promo', label: 'Promoção' }];
  const save = async (list: NotificationTemplate[]) => {
    const next = { ...config, notifications: { ...config.notifications, list } };
    try { await saveConfig(next); setConfig(next); return true; } catch { return false; }
  };
  const create = async () => {
    if (!draft.title.trim() || !draft.message.trim()) { toast.error('Preencha título e mensagem.'); return; }
    const saved = await save([{ id: `notif_${Date.now()}`, title: draft.title.trim(), message: draft.message.trim(), category: draft.category,
      createdAt: new Date().toISOString(), targetAll: true, dismissible: draft.category !== 'urgent' }, ...templates]);
    if (saved) setDraft({ title: '', message: '', category: 'info' });
  };
  const selectTemplate = (template: NotificationTemplate) => {
    const base = userRole === 'superAdmin' ? `/provedores/${providerId}/comunicados` : '/provedor/comunicados';
    navigate(`${base}/notificacoes`, { state: { title: template.title, body: template.message, category: template.category } });
  };
  return <SettingsPage title="Modelos salvos" description="Reutilize mensagens na tela de envio. Salvar um modelo não envia notificações." icon={Bell}>
    <div className="grid gap-5 lg:grid-cols-2">
      <SettingsSection title="Novo modelo"><div className="space-y-4">
        <div><Label htmlFor="template-title">Título</Label><Input id="template-title" value={draft.title} maxLength={50} onChange={event => setDraft({ ...draft, title: event.target.value })} /></div>
        <div><Label htmlFor="template-body">Mensagem</Label><Textarea id="template-body" value={draft.message} maxLength={500} onChange={event => setDraft({ ...draft, message: event.target.value })} /></div>
        <div><Label htmlFor="template-category">Categoria</Label><Select value={draft.category} onValueChange={category => setDraft({ ...draft, category })}>
          <SelectTrigger id="template-category"><SelectValue /></SelectTrigger><SelectContent>{categories.map(item => <SelectItem key={item.value} value={item.value}>{item.label}</SelectItem>)}</SelectContent>
        </Select></div>
        <Button onClick={() => void create()} disabled={isSaving}><Plus className="mr-2 h-4 w-4" />Salvar modelo</Button>
      </div></SettingsSection>
      <SettingsSection title="Seus modelos"><div className="space-y-3">
        {templates.length === 0 && <p className="text-sm text-muted-foreground">Nenhum modelo salvo.</p>}
        {templates.map(template => <div key={template.id} className="space-y-3 rounded-lg border bg-white p-4">
          <div className="flex flex-wrap items-center gap-2"><h3 className="font-semibold">{template.title}</h3><StatusBadge status={categories.find(item => item.value === template.category)?.label || template.category} tone="blue" /></div>
          <p className="whitespace-pre-wrap text-sm text-muted-foreground">{template.message}</p>
          <div className="flex justify-between gap-2"><Button variant="outline" onClick={() => selectTemplate(template)}>Usar no envio</Button>
            <Button variant="ghost" aria-label={`Excluir modelo ${template.title}`} disabled={isSaving} onClick={() => { if (window.confirm('Excluir este modelo salvo?')) void save(templates.filter(item => item.id !== template.id)); }}><Trash2 className="h-4 w-4" /></Button></div>
        </div>)}
      </div></SettingsSection>
    </div>
  </SettingsPage>;
}
