import { useState, useEffect } from 'react';
import { useSettings, ProviderConfig } from '@/contexts/SettingsContext';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Label } from '@/components/ui/label';
import { Button } from '@/components/ui/button';
import { Save, Loader2 } from 'lucide-react';
import RichTextEditor from '@/components/RichTextEditor';

export default function TermsOfUseSettings() {
    const { config, setConfig, saveConfig, isSaving, providerId } = useSettings();

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
    };

    const handleSave = async () => {
        try {
            await saveConfig({ ...config, termsOfUse: localTerms });
        } catch {
            // saveConfig já mostrou o erro.
        }
    };

    return (
        <Card>
            <CardHeader>
                <CardTitle>Termos de Serviço</CardTitle>
                <CardDescription>
                    O texto vira uma página pública com o link "Termos de uso" na tela de entrada e em Conta no app (versão 1.0.22 em diante).
                </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
                
                <div className="space-y-2">
                    <Label>Conteúdo do Termo de Serviço (HTML/Rich Text)</Label>
                    <RichTextEditor
                        value={localTerms}
                        onChange={handleSaveTerms} 
                    />
                    <p className="text-sm text-muted-foreground">
                        Na página pública o texto aparece em parágrafos simples (negrito e links não são mantidos). Enquanto estiver o texto de exemplo, o link não aparece.
                        {' '}
                        {providerId && <a className="underline" href={`https://appisp.com.br/api/public/providers/${providerId}/termos`} target="_blank" rel="noreferrer">Ver página publicada</a>}
                    </p>
                </div>

                <Button onClick={() => void handleSave()} disabled={isSaving}>
                    {isSaving ? <Loader2 className="mr-2 h-4 w-4 animate-spin" /> : <Save className="mr-2 h-4 w-4" />}
                    Salvar termos
                </Button>
                
            </CardContent>
        </Card>
    );
}
