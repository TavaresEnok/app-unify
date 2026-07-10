import { useState, useEffect } from 'react';
import { useSettings, ProviderConfig } from '@/contexts/SettingsContext';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Label } from '@/components/ui/label';
import { Button } from '@/components/ui/button';
import { Save, Loader2 } from 'lucide-react';
import { toast } from 'sonner';
import RichTextEditor from '@/components/RichTextEditor';

export default function TermsOfUseSettings() {
    const { config, setConfig, isSaving } = useSettings();

    const defaultTerms = "<p>Estes são os termos de uso padrão. Por favor, edite-os no painel.</p>";

    const [localTerms, setLocalTerms] = useState(config.termsOfUse || defaultTerms);

    useEffect(() => {
        setLocalTerms(config.termsOfUse || defaultTerms);
    }, [config.termsOfUse]);

    // Função para salvar localmente e atualizar o contexto
    const handleSaveTerms = (value: string) => {
        setLocalTerms(value);

        // Atualiza o contexto global
        // CORRIGIDO: Tipagem do prev para resolver TS7006
        setConfig((prev: ProviderConfig) => ({
            ...prev,
            termsOfUse: value,
        }));
        
        toast.info("Termos de Serviço atualizados localmente. Clique em 'Salvar Alterações' no topo da página para confirmar.");
    };

    return (
        <Card>
            <CardHeader>
                <CardTitle>Termos de Serviço</CardTitle>
                <CardDescription>
                    Defina o conteúdo do Termo de Serviço que será exibido no aplicativo.
                </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
                
                <div className="space-y-2">
                    <Label>Conteúdo do Termo de Serviço (HTML/Rich Text)</Label>
                    <RichTextEditor
                        value={localTerms}
                        onChange={handleSaveTerms} 
                    />
                    <p className="text-sm text-muted-foreground">O texto que aparece na seção "Termos de Serviço" (pode conter formatação HTML).</p>
                </div>

                <Button onClick={() => toast.success("Use o botão 'Salvar Alterações' no topo do painel.")} disabled={isSaving}>
                    {isSaving ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <Save className="mr-2 h-4 w-4" />}
                    Aplicar Edições (Local)
                </Button>
                
            </CardContent>
        </Card>
    );
}
