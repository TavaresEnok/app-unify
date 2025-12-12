import { useContext } from 'react';
import { SettingsContext } from '@/contexts/SettingsContext';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Switch } from "@/components/ui/switch";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Upload, Palette, Type, CreditCard, LayoutTemplate, Zap, Smartphone } from 'lucide-react';
import { toast } from 'sonner';

export default function AppearanceSettings() {
    const context = useContext(SettingsContext);
    if (!context) return null;

    const { config, setConfig } = context;

    const update = (key: string, val: string) => {
        setConfig((p: any) => ({ ...p, [key]: val }));
    };

    const ColorRow = ({ label, id, icon: Icon }: any) => {
        const val = config[id];
        return (
            <div className="space-y-2">
                <Label className="flex items-center gap-2 text-sm font-medium text-muted-foreground">
                    {Icon && <Icon className="h-4 w-4" />} {label}
                </Label>
                <div className="flex items-center gap-2">
                    <div className="relative group">
                        <Input type="color" className="w-12 h-10 p-1 cursor-pointer" value={val} onChange={e => update(id, e.target.value)} />
                    </div>
                    <Input value={val} onChange={e => update(id, e.target.value)} className="uppercase font-mono flex-1" maxLength={7} />
                </div>
            </div>
        );
    };

    return (
        <Card>
            <CardHeader><CardTitle>Aparência</CardTitle></CardHeader>
            <CardContent className="space-y-8">
                {/* Seletor de Layout do App */}
                <div className="space-y-3 p-4 border rounded-lg bg-muted/30">
                    <Label className="flex items-center gap-2 text-sm font-medium">
                        <Smartphone className="h-4 w-4" /> Layout do App
                    </Label>
                    <Select
                        value={config.layoutType || 'layout_06'}
                        onValueChange={(v) => setConfig((p: any) => ({ ...p, layoutType: v }))}
                    >
                        <SelectTrigger className="w-full">
                            <SelectValue placeholder="Escolha o layout" />
                        </SelectTrigger>
                        <SelectContent>
                            <SelectItem value="layout_02">Layout 02 - Clássico (Gradiente Roxo)</SelectItem>
                            <SelectItem value="layout_03">Layout 03 - Minimalista (Cards Brancos)</SelectItem>
                            <SelectItem value="layout_05">Layout 05 - Neo Digital (Futurista)</SelectItem>
                            <SelectItem value="layout_06">Layout 06 - Premium Dark (Recomendado)</SelectItem>
                            <SelectItem value="layout_07">Layout 07 - Clean Light</SelectItem>

                        </SelectContent>
                    </Select>
                    <p className="text-xs text-muted-foreground">Define a aparência visual do aplicativo do cliente</p>
                </div>

                {/* Cores */}
                <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
                    <ColorRow label="Botões (Ação)" id="actionColor" icon={Zap} />
                    <ColorRow label="Fatura" id="invoiceColor" icon={CreditCard} />
                    <ColorRow label="Texto" id="textColor" icon={Type} />
                    <ColorRow label="Texto" id="textColor" icon={Type} />
                </div>
                <div className="grid gap-6 sm:grid-cols-2">
                    <ColorRow label="Principal" id="themeColor" icon={Palette} />
                    <ColorRow label="Secundária" id="secondaryColor" icon={Palette} />
                </div>
                <div className="p-4 border rounded mt-4 flex justify-between items-center">
                    <Label>Cabeçalho com Imagem?</Label>
                    <Switch checked={config.other?.useBackgroundImage || false} onCheckedChange={(c) => setConfig((p: any) => ({ ...p, other: { ...(p.other || {}), useBackgroundImage: c } }))} />
                </div>
                <div className="mt-4 flex gap-2">
                    <Input value={config.logoUrl || ''} onChange={e => update('logoUrl', e.target.value)} placeholder="Logo URL" />
                    <Button variant="secondary" onClick={() => toast.success('URL OK')}>Definir</Button>
                </div>
            </CardContent>
        </Card>
    );
}
