import { useState, useContext, useEffect } from 'react';
import { SettingsContext, type ProviderConfig } from '@/contexts/SettingsContext';
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
import { buildMenuItems, serializeMenuItems, DEFAULT_MENU_COLOR, type MenuItem } from '@/features/provider-settings/menuItems';

function SortableRow({ item, index, onToggle, onRemove, onColorChange }: any) {
    const { attributes, listeners, setNodeRef, transform, transition } = useSortable({ id: item.id });
    const style = { transform: CSS.Transform.toString(transform), transition };

    return (
        <TableRow ref={setNodeRef} style={style}>
            <TableCell className="cursor-grab w-[50px]" aria-label={`Arrastar ${item.name}`} {...attributes} {...listeners}>
                <GripVertical className="h-5 w-5 text-muted-foreground" />
            </TableCell>
            <TableCell className="w-[50px]">{index + 1}</TableCell>
            <TableCell className="font-medium">{item.name}</TableCell>
            
            {/* COLUNA DE COR INDIVIDUAL */}
            <TableCell>
                <div className="flex items-center gap-2">
                    <div 
                        className="w-6 h-6 rounded-full border shadow-sm" 
                        style={{ backgroundColor: item.color || DEFAULT_MENU_COLOR }}
                    />
                    <Input 
                        type="color" 
                        value={item.color || DEFAULT_MENU_COLOR}
                        aria-label={`Cor de ${item.name}`}
                        onChange={(e) => onColorChange(item.id, e.target.value)}
                        className="w-12 h-8 p-0 cursor-pointer border-none bg-transparent"
                    />
                </div>
            </TableCell>

            <TableCell>{item.type === 'external_link' ? `Link: ${item.url}` : 'Nativo'}</TableCell>
            
            <TableCell className="text-right w-[150px]">
                <div className="flex items-center justify-end gap-4">
                  {item.type === 'external_link' && (
                    <Button variant="ghost" size="icon" aria-label={`Excluir ${item.name}`} title="Excluir" onClick={() => onRemove(item.id)}>
                        <Trash2 className="h-4 w-4 text-destructive" />
                    </Button>
                  )}
                  <Switch
                      aria-label={`Mostrar ${item.name} no app`}
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
        setMenuItems(buildMenuItems(context?.config?.menuConfig));
    }, [context?.config?.menuConfig]);

    const updateAndSave = (newItems: MenuItem[]) => {
      setMenuItems(newItems);
      if (context) {
          const newConfig = serializeMenuItems(newItems);
          context.setConfig((prev: ProviderConfig) => ({ ...prev, menuConfig: newConfig }));
      }
    };

    const handleAddItem = (name: string, url: string) => {
      const newItem: MenuItem = {
        id: `external_${Date.now()}`,
        name: name,
        type: 'external_link',
        url: url,
        color: DEFAULT_MENU_COLOR,
        enabled: true,
      };
      const updatedItems = [...menuItems, newItem];
      updateAndSave(updatedItems);
      toast.success(`'${name}' adicionado. Clique em 'Salvar alterações' no topo.`);
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
