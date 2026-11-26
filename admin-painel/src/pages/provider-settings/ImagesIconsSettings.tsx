import { useState, useEffect } from 'react';
import { useSettings, type ProviderConfig } from '@/contexts/SettingsContext';
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { Button } from '@/components/ui/button';
import { Upload, ImageIcon, Monitor } from 'lucide-react';
import { toast } from 'sonner';
import { SettingsPage, SettingsSection } from '@/components/settings/SettingsPage';
import ImageUploadButton from '@/components/ImageUploadButton';

interface ImageConfig {
    key: string;
    label: string;
    placeholder: string;
    previewSize: string;
}

const imageFields: ImageConfig[] = [
    { key: 'logoUrl', label: 'Logo do Provedor', placeholder: 'URL da logo (PNG ou JPEG)...', previewSize: 'h-24 w-auto' },
    { key: 'backgroundUrl', label: 'Imagem de Fundo (Login) — em breve no app', placeholder: 'URL da imagem de fundo...', previewSize: 'h-24 w-auto' },
    { key: 'iconUrl', label: 'Ícone da Aplicação — em breve no app', placeholder: 'URL do ícone...', previewSize: 'h-12 w-12' },
];

type LogoFraming = NonNullable<ProviderConfig['logoFraming']>;
const defaultFraming: Required<LogoFraming> = {
    shape: 'circle', fit: 'contain', zoom: 1, x: 50, y: 50,
};

const sliders = [
    { key: 'zoom', label: 'Zoom', min: 1, max: 3, step: 0.05 },
    { key: 'x', label: 'Posição horizontal', min: 0, max: 100, step: 1 },
    { key: 'y', label: 'Posição vertical', min: 0, max: 100, step: 1 },
] as const;

function LogoFramingEditor({ url, value, onChange, disabled }: {
    url: string;
    value: LogoFraming | undefined;
    onChange: (value: LogoFraming) => void;
    disabled: boolean;
}) {
    const framing = { ...defaultFraming, ...value };
    const update = (patch: LogoFraming) => onChange({ ...framing, ...patch });
    const position = `${framing.x}% ${framing.y}%`;
    const shape = framing.shape === 'wide' ? 'h-[100px] w-[200px] rounded-[20px]'
        : framing.shape === 'rounded' ? 'size-[100px] rounded-[20px]' : 'size-[100px] rounded-full';
    const selectClass = 'mt-1 block w-full rounded-md border border-input bg-background p-2 text-sm';
    return (
        <div className="mt-4 grid gap-4 rounded-lg border bg-muted/30 p-4 sm:grid-cols-[minmax(205px,auto)_1fr]">
            <figure className="self-center justify-self-center text-center">
                <div className={`mx-auto overflow-hidden bg-slate-100 ring-1 ring-slate-200 ${shape}`}>
                    <img key={url} src={url} alt="Logo na tela de login" className="size-full"
                        style={{ objectFit: framing.fit, objectPosition: position, transformOrigin: position, transform: `scale(${framing.zoom})` }} />
                </div>
                <figcaption className="mt-2 text-xs text-muted-foreground">Prévia no login</figcaption>
            </figure>
            <fieldset disabled={disabled} className="grid min-w-0 gap-3">
                <div className="grid gap-3 sm:grid-cols-2">
                    <div>
                        <Label htmlFor="logo-frame-shape">Formato</Label>
                        <select id="logo-frame-shape" className={selectClass} value={framing.shape}
                            onChange={e => update({ shape: e.target.value as LogoFraming['shape'] })}>
                            <option value="circle">Circular</option>
                            <option value="rounded">Quadrado arredondado</option>
                            <option value="wide">Horizontal</option>
                        </select>
                    </div>
                    <div>
                        <Label htmlFor="logo-frame-fit">Encaixe</Label>
                        <select id="logo-frame-fit" className={selectClass} value={framing.fit}
                            onChange={e => update({ fit: e.target.value as LogoFraming['fit'] })}>
                            <option value="contain">Mostrar imagem inteira</option>
                            <option value="cover">Preencher quadro</option>
                        </select>
                    </div>
                </div>
                {sliders.map(({ key, label, min, max, step }) => (
                    <Label key={key} className="grid gap-1">
                        <span className="flex justify-between gap-2"><span>{label}</span><span>{key === 'zoom' ? Math.round(framing[key] * 100) : framing[key]}%</span></span>
                        <input type="range" value={framing[key]} min={min} max={max} step={step}
                            onChange={e => update({ [key]: e.target.valueAsNumber })} />
                    </Label>
                ))}
                <Button type="button" variant="outline" size="sm" className="justify-self-start" onClick={() => onChange(defaultFraming)}>
                    Restaurar enquadramento
                </Button>
            </fieldset>
        </div>
    );
}

export default function ImagesIconsSettings() {
    const { config, setConfig, isSaving, providerId } = useSettings();

    // Estado local para gerenciar as URLs
    const [localUrls, setLocalUrls] = useState<Record<string, string>>(() => {
        const initial: Record<string, string> = {};
        imageFields.forEach(field => {
            initial[field.key] = config[field.key] || '';
        });
        return initial;
    });

    useEffect(() => {
        // Sincroniza o estado local com o estado global ao carregar a página
        setLocalUrls({
            backgroundUrl: config.backgroundUrl || '',
            logoUrl: config.logoUrl || '',
            iconUrl: config.iconUrl || '',
        });
    }, [config.backgroundUrl, config.logoUrl, config.iconUrl]);

    // Função para atualizar o estado local
    const handleLocalUpdate = (key: string, value: string) => {
        setLocalUrls(prev => ({ ...prev, [key]: value }));
    };

    const applyUploaded = (key: string, url: string) => {
        setLocalUrls(prev => ({ ...prev, [key]: url }));
        setConfig((prev) => ({ ...prev, [key]: url }));
        toast.success("Imagem enviada. Clique em 'Salvar alterações' no topo para publicar no app.");
    };

    // Função para salvar no contexto
    const handleSaveImage = (key: string) => {
        const url = localUrls[key]?.trim();
        if (!url || !/^https:\/\//i.test(url)) {
            toast.error(`Use um link https:// válido para ${imageFields.find(f => f.key === key)?.label}.`);
            return;
        }

        // Atualiza o contexto global
        // CORRIGIDO: Tipagem do prev para resolver TS7006
        setConfig((prev) => ({ ...prev, [key]: url }));
        toast.success(`${imageFields.find(f => f.key === key)?.label} atualizada. Clique em 'Salvar alterações' no topo.`);
    };

    return (
        <SettingsPage
            title="Imagens e Ícones"
            description="Envie a logo do computador ou cole um link público (https)."
            icon={ImageIcon}
        >
            <SettingsSection title="Ativos visuais" description="PNG, JPG ou WebP. Depois de enviar ou aplicar, clique em Salvar alterações no topo.">
                {imageFields.map((field) => (
                    <div key={field.key} className="mb-4 rounded-lg border border-[#EEF0F4] bg-white p-3 last:mb-0">
                        <Label htmlFor={field.key} className="mb-3 flex items-center gap-2 text-[12.5px] font-semibold text-[#39414F]">
                            {field.key === 'backgroundUrl' ? <Monitor className="h-4 w-4 text-[#98A1B1]" /> : <ImageIcon className="h-4 w-4 text-[#98A1B1]" />}
                            {field.label}
                        </Label>

                        <div className="flex flex-col gap-2 sm:flex-row">
                            <Input
                                id={field.key}
                                placeholder={field.placeholder}
                                value={localUrls[field.key] || ''}
                                onChange={(e) => handleLocalUpdate(field.key, e.target.value)}
                                disabled={isSaving}
                            />
                            <Button onClick={() => handleSaveImage(field.key)} disabled={isSaving || !localUrls[field.key]?.trim()}>
                                <Upload className="h-4 w-4 mr-2" /> Aplicar link
                            </Button>
                            <ImageUploadButton providerId={providerId} disabled={isSaving} onUploaded={(url) => applyUploaded(field.key, url)} />
                        </div>

                        {field.key === 'logoUrl' && localUrls.logoUrl && (
                            <LogoFramingEditor url={localUrls.logoUrl} value={config.logoFraming} disabled={isSaving}
                                onChange={logoFraming => setConfig(previous => ({ ...previous, logoFraming }))} />
                        )}
                        {field.key !== 'logoUrl' && localUrls[field.key] && (
                            <div className="mt-4 rounded-lg border border-[#EEF0F4] bg-[#FAFBFC] p-4">
                                <p className="mb-2 text-[12px] font-semibold text-[#687181]">Pré-visualização</p>
                                <img
                                    src={localUrls[field.key]}
                                    alt={`${field.label} Preview`}
                                    className={`${field.previewSize} object-contain`}
                                    onError={(e) => (e.currentTarget.style.display = 'none')}
                                />
                            </div>
                        )}
                    </div>
                ))}
            </SettingsSection>
        </SettingsPage>
    );
}
