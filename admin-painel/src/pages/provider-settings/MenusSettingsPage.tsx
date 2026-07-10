import { useState, useContext, useEffect } from 'react';
import { SettingsContext, ProviderConfig } from '@/contexts/SettingsContext';
import { Button } from '@/components/ui/button';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Input } from "@/components/ui/input";
import { GripVertical, Trash2 } from 'lucide-react';
import { toast } from 'sonner';
import { Switch } from "@/components/ui/switch";
import { DndContext, closestCenter, KeyboardSensor, PointerSensor, useSensor, useSensors, DragEndEvent } from '@dnd-kit/core';
import { arrayMove, SortableContext, sortableKeyboardCoordinates, verticalListSortingStrategy, useSortable } from '@dnd-kit/sortable';
import { CSS } from '@dnd-kit/utilities';
import AddMenuItemDialog from '@/components/AddMenuItemDialog';
import { SettingsPage, SettingsSection } from '@/components/settings/SettingsPage';

interface MenuItem {
  id: string;
  name: string;
  type: 'internal' | 'external_link';
  url?: string;
  color?: string; // Nova propriedade de cor individual
  enabled: boolean;
}

const defaultMenuItems: Omit<MenuItem, 'enabled'>[] = [
  { id: 'notifications', name: 'Notificações', type: 'internal', color: '#F59E0B' },
  { id: 'invoices', name: 'Faturas', type: 'internal', color: '#1E6FF8' },
  { id: 'payment_promise', name: 'Promessa de Pagamento', type: 'internal', color: '#10B981' },
  { id: 'speed_test', name: 'Teste de Velocidade', type: 'internal', color: '#8B5CF6' },
  { id: 'internet_usage', name: 'Consumo de Internet', type: 'internal', color: '#EC4899' },
  { id: 'support', name: 'Suporte', type: 'internal', color: '#06B6D4' },
  { id: 'contract', name: 'Contrato', type: 'internal', color: '#6366F1' },
  { id: 'my_ip', name: 'Meu IP', type: 'internal', color: '#F97316' },
];

function SortableRow({ item, index, onToggle, onRemove, onColorChange }: any) {
    const { attributes, listeners, setNodeRef, transform, transition } = useSortable({ id: item.id });
    const style = { transform: CSS.Transform.toString(transform), transition };

    return (
        <TableRow ref={setNodeRef} style={style}>
            <TableCell className="cursor-grab w-[50px]" {...attributes} {...listeners}>
                <GripVertical className="h-5 w-5 text-muted-foreground" />
            </TableCell>
            <TableCell className="w-[50px]">{index + 1}</TableCell>
            <TableCell className="font-medium">{item.name}</TableCell>
            
            {/* COLUNA DE COR INDIVIDUAL */}
            <TableCell>
                <div className="flex items-center gap-2">
                    <div 
                        className="w-6 h-6 rounded-full border shadow-sm" 
                        style={{ backgroundColor: item.color || '#673AB7' }}
                    />
                    <Input 
                        type="color" 
                        value={item.color || '#673AB7'} 
                        onChange={(e) => onColorChange(item.id, e.target.value)}
                        className="w-12 h-8 p-0 cursor-pointer border-none bg-transparent"
                    />
                </div>
            </TableCell>

            <TableCell>{item.type === 'external_link' ? `Link: ${item.url}` : 'Nativo'}</TableCell>
            
            <TableCell className="text-right w-[150px]">
                <div className="flex items-center justify-end gap-4">
                  {item.type === 'external_link' && (
                    <Button variant="ghost" size="icon" onClick={() => onRemove(item.id)}>
                        <Trash2 className="h-4 w-4 text-destructive" />
                    </Button>
                  )}
                  <Switch
                      checked={item.enabled}
                      onCheckedChange={(checked) => onToggle(item.id, checked)}
                  />
                </div>
            </TableCell>
        </TableRow>
    );
}

export default function MenusSettingsPage() {
    const context = useContext(SettingsContext);
    const [menuItems, setMenuItems] = useState<MenuItem[]>([]);
    const sensors = useSensors(useSensor(PointerSensor), useSensor(KeyboardSensor, { coordinateGetter: sortableKeyboardCoordinates }));

    useEffect(() => {
        const savedConfig = context?.config?.menuConfig as { order: string[], items: Record<string, MenuItem> } | undefined;

        if (savedConfig?.order && savedConfig?.items) {
            const allItems: MenuItem[] = savedConfig.order.map(id => {
                const savedItem = savedConfig.items[id];
                const defaultItem = defaultMenuItems.find(d => d.id === id);
                return {
                    id: id,
                    name: savedItem.name || defaultItem?.name || 'Item',
                    type: savedItem.type || defaultItem?.type || 'internal',
                    url: savedItem.url,
                    color: savedItem.color || defaultItem?.color || '#673AB7', // Recupera a cor salva
                    enabled: savedItem.enabled,
                };
            }).filter(item => defaultMenuItems.some(d => d.id === item.id) || item.type === 'external_link');
            
            defaultMenuItems.forEach(defaultItem => {
                if (!allItems.some(item => item.id === defaultItem.id)) {
                    allItems.push({ ...defaultItem, enabled: true });
                }
            });
            
            setMenuItems(allItems);
        } else {
            setMenuItems(defaultMenuItems.map(item => ({ ...item, enabled: true })));
        }
    }, [context?.config?.menuConfig]);
    
    const updateAndSave = (newItems: MenuItem[]) => {
      setMenuItems(newItems);
      if (context) {
          const newConfig = {
              order: newItems.map(item => item.id),
              items: newItems.reduce((acc, item) => {
                  const itemToSave: any = {
                      name: item.name,
                      type: item.type,
                      enabled: item.enabled,
                      color: item.color, // Salva a cor
                  };
                  if (item.type === 'external_link') itemToSave.url = item.url;
                  acc[item.id] = itemToSave;
                  return acc;
              }, {} as Record<string, Omit<MenuItem, 'id'>>)
          };
          context.setConfig((prev: ProviderConfig) => ({ ...prev, menuConfig: newConfig }));
      }
    };

    const handleAddItem = (name: string, url: string) => {
      const newItem: MenuItem = {
        id: `external_${Date.now()}`,
        name: name,
        type: 'external_link',
        url: url,
        color: '#673AB7', // Cor padrão para novos links
        enabled: true,
      };
      const updatedItems = [...menuItems, newItem];
      updateAndSave(updatedItems);
      toast.success(`'${name}' adicionado. Clique em 'Salvar Alterações'.`);
    };

    const handleRemoveItem = (id: string) => {
      const updatedItems = menuItems.filter(item => item.id !== id);
      updateAndSave(updatedItems);
    };

    const handleDragEnd = (event: DragEndEvent) => {
        const { active, over } = event;
        if (over && active.id !== over.id) {
            const oldIndex = menuItems.findIndex(item => item.id === active.id);
            const newIndex = menuItems.findIndex(item => item.id === over.id);
            const reorderedItems = arrayMove(menuItems, oldIndex, newIndex);
            updateAndSave(reorderedItems);
        }
    };

    const handleToggle = (id: string, enabled: boolean) => {
        const updatedItems = menuItems.map(item => item.id === id ? { ...item, enabled } : item);
        updateAndSave(updatedItems);
    };

    // Nova função para mudar a cor
    const handleColorChange = (id: string, color: string) => {
        const updatedItems = menuItems.map(item => item.id === id ? { ...item, color } : item);
        updateAndSave(updatedItems);
    };

    return (
        <SettingsPage
            title="Menus & Cores"
            description="Organize os menus e defina uma cor para cada cartão."
            icon={GripVertical}
            actions={<AddMenuItemDialog onAddItem={handleAddItem} />}
        >
            <SettingsSection title="Itens do menu" description="Arraste para reordenar e use os switches para controlar visibilidade.">
                <DndContext sensors={sensors} collisionDetection={closestCenter} onDragEnd={handleDragEnd}>
                    <Table>
                        <TableHeader>
                            <TableRow>
                                <TableHead className="w-[50px]"></TableHead>
                                <TableHead className="w-[50px]">#</TableHead>
                                <TableHead>Nome</TableHead>
                                <TableHead>Cor do Card</TableHead>
                                <TableHead>Tipo</TableHead>
                                <TableHead className="text-right w-[150px]">Ações</TableHead>
                            </TableRow>
                        </TableHeader>
                        <TableBody>
                            <SortableContext items={menuItems.map(i => i.id)} strategy={verticalListSortingStrategy}>
                                {menuItems.map((item, index) => (
                                    <SortableRow 
                                        key={item.id} 
                                        item={item} 
                                        index={index} 
                                        onToggle={handleToggle} 
                                        onRemove={handleRemoveItem}
                                        onColorChange={handleColorChange} // Passa a função
                                    />
                                ))}
                            </SortableContext>
                        </TableBody>
                    </Table>
                </DndContext>
            </SettingsSection>
        </SettingsPage>
    );
}
