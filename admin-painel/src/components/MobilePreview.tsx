import { useSettings } from '@/contexts/SettingsContext';
import { AppearancePreview } from '@/pages/provider-settings/AppearanceSettings';

export default function MobilePreview() {
    const { config } = useSettings();
    return <AppearancePreview config={config} />;
}
