import { useContext, useState, useEffect } from 'react';
import { SettingsContext, ProviderConfig } from '@/contexts/SettingsContext';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Label } from '@/components/ui/label';
import { Button } from '@/components/ui/button';
import { Switch } from '@/components/ui/switch';
import { Save, Loader2, Zap, MessageSquare, ScrollText, DollarSign, Gauge, Clock, Menu } from 'lucide-react';
import { toast } from 'sonner';

interface Feature {
    key: string;
    label: string;
    description: string;
    icon: React.ReactNode;
}

const defaultFeatures: Feature[] = [
    { key: 'consumption', label: 'Consumo de Internet', description: 'Permite que o cliente veja o extrato de uso de dados.', icon: <Gauge className="h-5 w-5" /> },
    { key: 'support', label: 'Suporte & Tickets', description: 'Ativa a abertura de tickets de suporte e contatos rápidos.', icon: <MessageSquare className="h-5 w-5" /> },
    { key: 'invoices', label: 'Faturas/Boletos', description: 'Permite ao cliente visualizar e baixar faturas em aberto.', icon: <DollarSign className="h-5 w-5" /> },
    { key: 'payment_promise', label: 'Promessa de Pagamento', description: 'Permite a liberação temporária de bloqueio por inadimplência.', icon: <Clock className="h-5 w-5" /> },
    { key: 'speed_test', label: 'Teste de Velocidade', description: 'Integração com teste de velocidade (necessita configuração).', icon: <Zap className="h-5 w-5" /> },
    { key: 'terms_of_use', label: 'Termos de Uso', description: 'Exibe os termos de serviço configurados no painel.', icon: <ScrollText className="h-5 w-5" /> },
    { key: 'custom_menu', label: 'Menu Lateral Personalizado', description: 'Permite a inclusão de links externos no menu lateral.', icon: <Menu className="h-5 w-5" /> },
];

export default function FeaturesSettings() {
    const context = useContext(SettingsContext);
    if (!context) return null;

    const { config, setConfig, isSaving } = context;

    // Estado local para gerenciar as features ativas/inativas
    const [localFeatures, setLocalFeatures] = useState<Record<string, boolean>>(config.features || {});

    useEffect(() => {
        // Sincroniza o estado local com o estado global ao carregar a página
        setLocalFeatures(config.features || {});
    }, [config]);

    const handleToggle = (key: string, checked: boolean) => {
        setLocalFeatures(prev => ({ ...prev, [key]: checked }));

        // Atualiza o contexto, aninhando a nova configuração de features
        // CORRIGIDO: Tipagem do prevConfig para resolver TS7006
        setConfig((prevConfig: ProviderConfig) => ({
            ...prevConfig,
            features: {
                ...prevConfig.features,
                [key]: checked,
            }
        }));
        
        toast.info(`Funcionalidade '${defaultFeatures.find(f => f.key === key)?.label}' ${checked ? 'ativada' : 'desativada'} localmente.`);
    };

    const handleApplyFeatures = () => {
        // O setConfig já foi chamado em cada toggle, então esta função apenas notifica
        toast.success("Configurações de funcionalidades aplicadas. Clique em 'Salvar Alterações' no topo da página para confirmar.");
    };

    return (
        <Card>
            <CardHeader>
                <CardTitle>Funcionalidades do Aplicativo</CardTitle>
                <CardDescription>
                    Selecione quais módulos e recursos estarão visíveis e acessíveis no aplicativo.
                </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
                
                {defaultFeatures.map((feature) => (
                    <div key={feature.key} className="flex items-center justify-between border-b pb-4 last:border-b-0">
                        <div className="flex items-start gap-3">
                            <div className="mt-1 text-primary flex-shrink-0">{feature.icon}</div>
                            <div>
                                <Label htmlFor={feature.key} className="font-semibold text-base">{feature.label}</Label>
                                <p className="text-sm text-muted-foreground">{feature.description}</p>
                            </div>
                        </div>
                        <Switch
                            id={feature.key}
                            checked={localFeatures[feature.key] ?? true} // Padrão: Ativo
                            onCheckedChange={(checked) => handleToggle(feature.key, checked)}
                            disabled={isSaving}
                        />
                    </div>
                ))}
                
                <Button onClick={handleApplyFeatures} disabled={isSaving}>
                    {isSaving ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <Save className="mr-2 h-4 w-4" />}
                    Aplicar Configurações de Recursos
                </Button>
                
            </CardContent>
        </Card>
    );
}
