// src/pages/provider-settings/ForceUpdate.tsx
import { useState, useEffect } from 'react';
import { useParams } from 'react-router-dom';
import {
  Card, CardContent, CardHeader, CardTitle, CardDescription
} from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Switch } from '@/components/ui/switch';
// import { Alert, AlertDescription } from '@/components/ui/alert';
import { Loader2, Save, AlertTriangle, CheckCircle2, Smartphone } from 'lucide-react';
import { toast } from 'sonner';

interface ForceUpdateConfig {
  minVersion: string;
  latestVersion: string;
  forceUpdate: boolean;
  updateMessage: {
    pt_BR: {
      title: string;
      message: string;
      buttonText: string;
    };
  };
  storeUrls: {
    android: string;
    ios: string;
  };
}

export default function ForceUpdate() {
  const { id: providerId } = useParams();
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const [config, setConfig] = useState<ForceUpdateConfig>({
    minVersion: '1.0.0',
    latestVersion: '1.0.0',
    forceUpdate: false,
    updateMessage: {
      pt_BR: {
        title: 'Atualização Necessária',
        message: 'Uma nova versão do app está disponível com melhorias importantes. Por favor, atualize para continuar.',
        buttonText: 'Atualizar Agora',
      },
    },
    storeUrls: {
      android: '',
      ios: '',
    },
  });

  useEffect(() => {
    if (providerId) {
      loadConfig();
    }
  }, [providerId]);

  const loadConfig = async () => {
    try {
      setLoading(true);
      const res = await fetch(`/api/providers/${providerId}/force-update`);
      if (res.ok) {
        const data = await res.json();
        if (data.appVersion) {
          setConfig(data.appVersion);
        }
      }
    } catch (err) {
      console.error('Erro ao carregar config:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async () => {
    setError(null);

    if (!isValidVersion(config.minVersion)) {
      setError('Versão mínima inválida. Use formato X.Y.Z (ex: 1.0.0)');
      return;
    }
    if (!isValidVersion(config.latestVersion)) {
      setError('Última versão inválida. Use formato X.Y.Z (ex: 1.2.0)');
      return;
    }
    if (config.forceUpdate && !config.storeUrls.android && !config.storeUrls.ios) {
      setError('Adicione pelo menos um link de loja (Android ou iOS)');
      return;
    }

    try {
      setSaving(true);
      const res = await fetch(`/api/providers/${providerId}/force-update`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ appVersion: config }),
      });

      if (!res.ok) throw new Error('Erro ao salvar configuração');

      toast.success('Configuração salva com sucesso!');
    } catch (err) {
      toast.error(err instanceof Error ? err.message : 'Erro ao salvar');
    } finally {
      setSaving(false);
    }
  };

  const isValidVersion = (version: string): boolean => {
    return /^\d+\.\d+\.\d+$/.test(version);
  };

  const compareVersions = (v1: string, v2: string): number => {
    const parts1 = v1.split('.').map(Number);
    const parts2 = v2.split('.').map(Number);
    for (let i = 0; i < 3; i++) {
      if (parts1[i] > parts2[i]) return 1;
      if (parts1[i] < parts2[i]) return -1;
    }
    return 0;
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-96">
        <Loader2 className="w-8 h-8 animate-spin text-primary" />
      </div>
    );
  }

  const versionWarning = compareVersions(config.minVersion, config.latestVersion) > 0;

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-3xl font-bold flex items-center gap-2">
            <Smartphone className="h-8 w-8" />
            Atualização Forçada
          </h2>
          <p className="text-muted-foreground">
            Configure a verificação de versão do app e bloqueie versões antigas
          </p>
        </div>
        <Button onClick={handleSave} disabled={saving || versionWarning}>
          {saving ? (
            <>
              <Loader2 className="w-4 h-4 mr-2 animate-spin" />
              Salvando...
            </>
          ) : (
            <>
              <Save className="w-4 h-4 mr-2" />
              Salvar
            </>
          )}
        </Button>
      </div>

      {error && (
        <div className="p-4 rounded-lg bg-orange-50 border border-orange-200">
          <p className="text-sm text-orange-800">
            {error}
          </p>
        </div>
      )}

      <Card>
        <CardHeader>
          <CardTitle>Ativação</CardTitle>
          <CardDescription>
            Ative para bloquear usuários com versões antigas do app
          </CardDescription>
        </CardHeader>
        <CardContent>
          <div className="flex items-center justify-between">
            <div>
              <Label htmlFor="force-update" className="text-base font-medium">
                Forçar Atualização
              </Label>
              <p className="text-sm text-muted-foreground mt-1">
                Quando ativo, usuários abaixo da versão mínima serão bloqueados
              </p>
            </div>
            <Switch
              id="force-update"
              checked={config.forceUpdate}
              onCheckedChange={(checked) =>
                setConfig({ ...config, forceUpdate: checked })
              }
            />
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Versões do App</CardTitle>
          <CardDescription>
            Configure as versões mínima e mais recente (formato: X.Y.Z)
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div>
            <Label htmlFor="min-version">
              Versão Mínima <span className="text-red-500">*</span>
            </Label>
            <Input
              id="min-version"
              placeholder="1.0.0"
              value={config.minVersion}
              onChange={(e) =>
                setConfig({ ...config, minVersion: e.target.value })
              }
              className="mt-1"
            />
            <p className="text-xs text-muted-foreground mt-1">
              Usuários abaixo desta versão serão bloqueados
            </p>
          </div>

          <div>
            <Label htmlFor="latest-version">Última Versão</Label>
            <Input
              id="latest-version"
              placeholder="1.2.0"
              value={config.latestVersion}
              onChange={(e) =>
                setConfig({ ...config, latestVersion: e.target.value })
              }
              className="mt-1"
            />
          </div>

          {versionWarning && (
            <div className="p-4 rounded-lg bg-red-50 border border-red-200">
              <p className="text-sm text-red-800 flex items-center gap-2">
                <AlertTriangle className="h-4 w-4" />
                A versão mínima não pode ser maior que a última versão
              </p>
            </div>
          )}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Mensagens Customizadas</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div>
            <Label htmlFor="msg-title">Título</Label>
            <Input
              id="msg-title"
              value={config.updateMessage.pt_BR.title}
              onChange={(e) =>
                setConfig({
                  ...config,
                  updateMessage: {
                    pt_BR: {
                      ...config.updateMessage.pt_BR,
                      title: e.target.value,
                    },
                  },
                })
              }
              className="mt-1"
            />
          </div>

          <div>
            <Label htmlFor="msg-message">Mensagem</Label>
            <Textarea
              id="msg-message"
              value={config.updateMessage.pt_BR.message}
              onChange={(e) =>
                setConfig({
                  ...config,
                  updateMessage: {
                    pt_BR: {
                      ...config.updateMessage.pt_BR,
                      message: e.target.value,
                    },
                  },
                })
              }
              className="mt-1"
              rows={3}
            />
          </div>

          <div>
            <Label htmlFor="msg-button">Texto do Botão</Label>
            <Input
              id="msg-button"
              value={config.updateMessage.pt_BR.buttonText}
              onChange={(e) =>
                setConfig({
                  ...config,
                  updateMessage: {
                    pt_BR: {
                      ...config.updateMessage.pt_BR,
                      buttonText: e.target.value,
                    },
                  },
                })
              }
              className="mt-1"
            />
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Links das Lojas</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div>
            <Label htmlFor="android-url">Google Play Store</Label>
            <Input
              id="android-url"
              type="url"
              placeholder="https://play.google.com/store/apps/details?id=com.yourapp"
              value={config.storeUrls.android}
              onChange={(e) =>
                setConfig({
                  ...config,
                  storeUrls: { ...config.storeUrls, android: e.target.value },
                })
              }
              className="mt-1"
            />
          </div>

          <div>
            <Label htmlFor="ios-url">Apple App Store</Label>
            <Input
              id="ios-url"
              type="url"
              placeholder="https://apps.apple.com/br/app/yourapp/id123456789"
              value={config.storeUrls.ios}
              onChange={(e) =>
                setConfig({
                  ...config,
                  storeUrls: { ...config.storeUrls, ios: e.target.value },
                })
              }
              className="mt-1"
            />
          </div>
        </CardContent>
      </Card>

      <Card className="border-2 border-dashed">
        <CardHeader>
          <CardTitle className="text-lg">Preview da Tela no App</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="bg-gradient-to-br from-blue-50 to-indigo-50 dark:from-gray-800 dark:to-gray-900 rounded-lg p-8 text-center">
            <div className="w-16 h-16 bg-primary/20 rounded-full mx-auto flex items-center justify-center mb-4">
              <Smartphone className="w-8 h-8 text-primary" />
            </div>
            <h3 className="text-xl font-bold mb-2">
              {config.updateMessage.pt_BR.title}
            </h3>
            <p className="text-muted-foreground mb-4 max-w-md mx-auto">
              {config.updateMessage.pt_BR.message}
            </p>
            <div className="bg-white dark:bg-gray-800 rounded p-3 max-w-xs mx-auto mb-4 text-sm">
              <div className="flex justify-between mb-1">
                <span className="text-muted-foreground">Versão Mínima:</span>
                <span className="font-semibold">{config.minVersion}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-muted-foreground">Última Versão:</span>
                <span className="font-semibold">{config.latestVersion}</span>
              </div>
            </div>
            <Button className="bg-primary hover:bg-primary/90">
              {config.updateMessage.pt_BR.buttonText}
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
