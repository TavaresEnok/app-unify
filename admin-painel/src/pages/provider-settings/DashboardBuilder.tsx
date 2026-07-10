import { useState } from 'react';
import { useSettings } from '@/contexts/SettingsContext';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Switch } from '@/components/ui/switch';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';
import { toast } from 'sonner';
import { Save, Eye, Trash2, BarChart3, Image as ImageIcon, Grid3x3, TrendingUp, ChevronUp, ChevronDown } from 'lucide-react';
import { SettingsPage, SettingsSection } from '@/components/settings/SettingsPage';

type WidgetType = 'stats_card' | 'banner' | 'action_grid' | 'carousel' | 'chart' | 'announcements' | 'quick_pay' | 'speed_test' | 'usage_meter';

interface Widget {
  id: string;
  type: WidgetType;
  position: number;
  visible: boolean;
  title?: string;
  config: any;
}

const widgetIcons: Record<WidgetType, any> = {
  stats_card: BarChart3,
  banner: ImageIcon,
  action_grid: Grid3x3,
  carousel: ImageIcon,
  chart: TrendingUp,
  announcements: BarChart3,
  quick_pay: BarChart3,
  speed_test: TrendingUp,
  usage_meter: BarChart3,
};

const widgetLabels: Record<WidgetType, string> = {
  stats_card: 'Card de Estatísticas',
  banner: 'Banner Promocional',
  action_grid: 'Grid de Ações',
  carousel: 'Carrossel',
  chart: 'Gráfico',
  announcements: 'Avisos',
  quick_pay: 'Pagamento Rápido',
  speed_test: 'Teste de Velocidade',
  usage_meter: 'Medidor de Consumo',
};

export default function DashboardBuilder() {
  const { config, setConfig, saveConfig, isSaving } = useSettings();
  const [widgets, setWidgets] = useState<Widget[]>(config.dashboardConfig?.widgets || config.dashboard?.widgets || []);
  const [editingWidget, setEditingWidget] = useState<Widget | null>(null);
  const [showPreview, setShowPreview] = useState(false);

  const addWidget = (type: WidgetType) => {
    const newWidget: Widget = {
      id: `widget_${Date.now()}`,
      type,
      position: widgets.length + 1,
      visible: true,
      title: widgetLabels[type],
      config: getDefaultConfig(type),
    };
    setWidgets([...widgets, newWidget]);
    setEditingWidget(newWidget);
    toast.success('Widget adicionado!');
  };

  const deleteWidget = (id: string) => {
    if (confirm('Remover este widget?')) {
      setWidgets(widgets.filter((w) => w.id !== id));
      toast.success('Widget removido!');
    }
  };

  const moveWidget = (id: string, direction: 'up' | 'down') => {
    const index = widgets.findIndex(w => w.id === id);
    if (index === -1) return;
    
    const newIndex = direction === 'up' ? index - 1 : index + 1;
    if (newIndex < 0 || newIndex >= widgets.length) return;
    
    const newWidgets = [...widgets];
    [newWidgets[index], newWidgets[newIndex]] = [newWidgets[newIndex], newWidgets[index]];
    
    // Atualiza posições
    newWidgets.forEach((w, i) => w.position = i + 1);
    setWidgets(newWidgets);
  };

  const updateWidget = (updatedWidget: Widget) => {
    setWidgets(widgets.map((w) => (w.id === updatedWidget.id ? updatedWidget : w)));
    setEditingWidget(null);
    toast.success('Widget atualizado!');
  };

  const handleSave = async () => {
    const dashboardConfig = { ...config.dashboardConfig, ...config.dashboard, widgets };
    const nextConfig = { ...config, dashboardConfig, dashboard: dashboardConfig };
    setConfig(nextConfig);
    await saveConfig(nextConfig);
    toast.success('Dashboard salvo com sucesso!');
  };

  return (
    <SettingsPage
      title="Dashboard Builder"
      description="Monte o dashboard perfeito para seus clientes."
      icon={Grid3x3}
      actions={(
        <>
          <Button variant="outline" onClick={() => setShowPreview(!showPreview)}>
            <Eye className="h-4 w-4 mr-2" />
            {showPreview ? 'Esconder' : 'Preview'}
          </Button>
          <Button onClick={handleSave} disabled={isSaving}>
            <Save className="h-4 w-4 mr-2" />
            {isSaving ? 'Salvando...' : 'Salvar Dashboard'}
          </Button>
        </>
      )}
    >

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Widgets List */}
        <div className="lg:col-span-2 space-y-4">
          <SettingsSection title={`Widgets ativos (${widgets.length})`} description="Use as setas para reordenar.">
              {widgets.length === 0 ? (
                <div className="text-center py-12 text-muted-foreground">
                  <Grid3x3 className="h-12 w-12 mx-auto mb-4 opacity-20" />
                  <p>Nenhum widget adicionado</p>
                  <p className="text-sm">Use o painel ao lado para adicionar widgets</p>
                </div>
              ) : (
                <div className="space-y-2">
                  {widgets.map((widget, index) => {
                    const Icon = widgetIcons[widget.type];
                    return (
                      <div key={widget.id} className={`flex items-center gap-4 rounded-lg border border-[#EEF0F4] bg-white p-4 ${widget.visible ? '' : 'opacity-50'}`}>
                          <div className="flex flex-col gap-1">
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => moveWidget(widget.id, 'up')}
                              disabled={index === 0}
                              className="h-6 w-6 p-0"
                            >
                              <ChevronUp className="h-4 w-4" />
                            </Button>
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => moveWidget(widget.id, 'down')}
                              disabled={index === widgets.length - 1}
                              className="h-6 w-6 p-0"
                            >
                              <ChevronDown className="h-4 w-4" />
                            </Button>
                          </div>

                          <Icon className="h-5 w-5" />

                          <div className="flex-1">
                            <p className="font-medium">{widget.title || widgetLabels[widget.type]}</p>
                            <p className="text-sm text-muted-foreground">Posição: {widget.position}</p>
                          </div>

                          <Badge variant={widget.visible ? 'default' : 'secondary'}>
                            {widget.visible ? 'Visível' : 'Oculto'}
                          </Badge>

                          <Button variant="ghost" size="sm" onClick={() => setEditingWidget(widget)}>
                            Editar
                          </Button>

                          <Button variant="ghost" size="sm" onClick={() => deleteWidget(widget.id)}>
                            <Trash2 className="h-4 w-4 text-destructive" />
                          </Button>
                      </div>
                    );
                  })}
                </div>
              )}
          </SettingsSection>
        </div>

        {/* Add Widgets Panel */}
        <div className="space-y-4">
          <SettingsSection title="Adicionar widget" description="Inclua novos blocos no dashboard.">
            <div className="space-y-2">
              {(Object.entries(widgetLabels) as [WidgetType, string][]).map(([type, label]) => {
                const Icon = widgetIcons[type];
                return (
                  <Button
                    key={type}
                    variant="outline"
                    className="w-full justify-start"
                    onClick={() => addWidget(type)}
                  >
                    <Icon className="h-4 w-4 mr-2" />
                    {label}
                  </Button>
                );
              })}
            </div>
          </SettingsSection>

          {/* Preview */}
          {showPreview && (
            <SettingsSection title="Preview Mobile" description="Ordem visual dos widgets ativos.">
                <div className="w-full aspect-[9/19.5] border-4 border-gray-800 rounded-3xl overflow-hidden bg-gray-900">
                  <div className="h-full overflow-auto bg-white p-4 space-y-3">
                    {widgets
                      .filter((w) => w.visible)
                      .sort((a, b) => a.position - b.position)
                      .map((widget) => (
                        <div
                          key={widget.id}
                          className="p-4 bg-gray-100 rounded-lg border text-center text-sm"
                        >
                          {widget.title || widgetLabels[widget.type]}
                        </div>
                      ))}
                  </div>
                </div>
            </SettingsSection>
          )}
        </div>
      </div>

      {/* Widget Editor Modal */}
      {editingWidget && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <Card className="w-full max-w-2xl max-h-[80vh] overflow-auto">
            <CardHeader>
              <CardTitle>Editar {widgetLabels[editingWidget.type]}</CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <Label>Título do Widget</Label>
                <Input
                  value={editingWidget.title || ''}
                  onChange={(e) => setEditingWidget({ ...editingWidget, title: e.target.value })}
                />
              </div>

              <div className="flex items-center justify-between">
                <Label>Visível</Label>
                <Switch
                  checked={editingWidget.visible}
                  onCheckedChange={(checked) => setEditingWidget({ ...editingWidget, visible: checked })}
                />
              </div>

              <Separator />

              <div className="text-sm text-muted-foreground">
                Configurações específicas do widget serão implementadas em breve...
              </div>

              <div className="flex gap-2 pt-4">
                <Button onClick={() => updateWidget(editingWidget)} className="flex-1">
                  Salvar Alterações
                </Button>
                <Button variant="outline" onClick={() => setEditingWidget(null)}>
                  Cancelar
                </Button>
              </div>
            </CardContent>
          </Card>
        </div>
      )}
    </SettingsPage>
  );
}

function getDefaultConfig(type: WidgetType): any {
  switch (type) {
    case 'stats_card':
      return { showInvoice: true, showConnection: true, showPlan: true };
    case 'banner':
      return { imageUrl: '', height: 150, borderRadius: 16 };
    case 'action_grid':
      return { columns: 3, showLabels: true, iconSize: 32, actions: [] };
    case 'chart':
      return { chartType: 'line', period: 7, height: 200 };
    default:
      return {};
  }
}
