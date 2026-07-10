import { useState } from 'react';
import { useSettings } from '@/contexts/SettingsContext';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Switch } from '@/components/ui/switch';
import { toast } from 'sonner';
import { Tag, Calendar, Percent, Trash2 } from 'lucide-react';
import { SettingsPage, SettingsSection } from '@/components/settings/SettingsPage';
import StatusBadge from '@/components/StatusBadge';

export default function PromotionsManager() {
  const { config, setConfig, saveConfig, isSaving } = useSettings();
  const [promotions, setPromotions] = useState(config.promotions?.items || []);
  const [newPromo, setNewPromo] = useState({
    title: '',
    description: '',
    badge: 'OFERTA',
    imageUrl: '',
    startDate: '',
    endDate: '',
    showCountdown: true,
  });

  const createPromotion = () => {
    if (!newPromo.title || !newPromo.startDate || !newPromo.endDate) {
      toast.error('Preencha título e datas');
      return;
    }
    const promo = {
      id: `promo_${Date.now()}`,
      ...newPromo,
      status: 'active',
      type: 'discount',
      createdAt: new Date().toISOString(),
    };
    setPromotions([...promotions, promo]);
    setNewPromo({ title: '', description: '', badge: 'OFERTA', imageUrl: '', startDate: '', endDate: '', showCountdown: true });
    toast.success('Promoção criada!');
  };

  const deletePromotion = (id: string) => {
    if (confirm('Deletar promoção?')) {
      setPromotions(promotions.filter((p: any) => p.id !== id));
      toast.success('Deletada!');
    }
  };

  const handleSave = async () => {
    setConfig({ ...config, promotions: { enabled: true, items: promotions } });
    await saveConfig();
    toast.success('Promoções salvas!');
  };

  return (
    <SettingsPage
      title="Promoções"
      description="Crie ofertas especiais para seus clientes."
      icon={Tag}
      actions={<Button onClick={handleSave} disabled={isSaving}>{isSaving ? 'Salvando...' : 'Salvar promoções'}</Button>}
      contentClassName="space-y-4"
    >

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <SettingsSection title="Nova promoção" description="Defina a oferta, período e contador." className="lg:col-span-1">
          <div className="space-y-4">
            <div>
              <Label>Título *</Label>
              <Input
                value={newPromo.title}
                onChange={(e) => setNewPromo({ ...newPromo, title: e.target.value })}
                placeholder="Ex: Black Friday 50% OFF"
              />
            </div>

            <div>
              <Label>Descrição</Label>
              <Textarea
                value={newPromo.description}
                onChange={(e) => setNewPromo({ ...newPromo, description: e.target.value })}
                placeholder="Detalhes da promoção..."
                rows={3}
              />
            </div>

            <div>
              <Label>Badge/Etiqueta</Label>
              <Input
                value={newPromo.badge}
                onChange={(e) => setNewPromo({ ...newPromo, badge: e.target.value })}
                placeholder="Ex: EXCLUSIVO"
              />
            </div>

            <div>
              <Label>URL da Imagem (opcional)</Label>
              <Input
                value={newPromo.imageUrl}
                onChange={(e) => setNewPromo({ ...newPromo, imageUrl: e.target.value })}
                placeholder="https://..."
              />
            </div>

            <div className="grid grid-cols-2 gap-2">
              <div>
                <Label>Data Início *</Label>
                <Input
                  type="date"
                  value={newPromo.startDate}
                  onChange={(e) => setNewPromo({ ...newPromo, startDate: e.target.value })}
                />
              </div>
              <div>
                <Label>Data Fim *</Label>
                <Input
                  type="date"
                  value={newPromo.endDate}
                  onChange={(e) => setNewPromo({ ...newPromo, endDate: e.target.value })}
                />
              </div>
            </div>

            <div className="flex items-center justify-between">
              <Label>Mostrar Contador Regressivo</Label>
              <Switch
                checked={newPromo.showCountdown}
                onCheckedChange={(c) => setNewPromo({ ...newPromo, showCountdown: c })}
              />
            </div>

            <Button onClick={createPromotion} className="w-full">
              <Tag className="h-4 w-4 mr-2" />
              Criar Promoção
            </Button>
          </div>
        </SettingsSection>

        <SettingsSection title={`Promoções ativas (${promotions.length})`} description="Campanhas cadastradas para exibição no app." className="lg:col-span-2">
            <div className="space-y-4">
              {promotions.length === 0 ? (
                <div className="text-center py-12">
                  <Percent className="h-12 w-12 mx-auto text-muted-foreground opacity-20 mb-4" />
                  <p className="text-muted-foreground">Nenhuma promoção criada</p>
                </div>
              ) : (
                promotions.map((promo: any) => (
                  <div key={promo.id} className="rounded-lg border border-[#EEF0F4] bg-white p-4 transition-colors hover:bg-[#F8FAFC]">
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        <div className="flex items-center gap-2 mb-2">
                          <h4 className="font-semibold text-lg">{promo.title}</h4>
                          {promo.badge && <StatusBadge status={promo.badge} tone="amber" />}
                          <StatusBadge status={promo.status} />
                        </div>
                        {promo.description && (
                          <p className="text-sm text-muted-foreground mb-3">{promo.description}</p>
                        )}
                        <div className="flex items-center gap-4 text-sm text-muted-foreground">
                          <span className="flex items-center gap-1">
                            <Calendar className="h-4 w-4" />
                            {new Date(promo.startDate).toLocaleDateString('pt-BR')}
                          </span>
                          <span>até</span>
                          <span>{new Date(promo.endDate).toLocaleDateString('pt-BR')}</span>
                          {promo.showCountdown && <StatusBadge status="Com countdown" tone="gray" />}
                        </div>
                      </div>
                      <Button variant="ghost" size="sm" onClick={() => deletePromotion(promo.id)}>
                        <Trash2 className="h-4 w-4 text-destructive" />
                      </Button>
                    </div>
                  </div>
                ))
              )}
            </div>
        </SettingsSection>
      </div>
    </SettingsPage>
  );
}
