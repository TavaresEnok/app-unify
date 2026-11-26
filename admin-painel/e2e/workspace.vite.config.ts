import path from 'node:path';
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
const root = path.resolve(__dirname, '..');
const workspace = path.resolve(__dirname, 'fixtures/workspace.tsx');
export default defineConfig({
  root,
  plugins: [react()],
  resolve: { alias: [
    { find: '@/shared/settings/buildSession', replacement: path.resolve(__dirname, 'fixtures/buildSession.ts') },
    ...['@/shared/api/panelHttp', '@/contexts/AuthContext', '@/firebase/auth', '@/firebase/config', '@/hooks/useApi', '@/shared/settings/providerSettingsService', '@/features/providers/providerService'].map(find => ({ find, replacement: workspace })),
    // Módulos de src/shared/api importam o cliente HTTP por caminho relativo.
    { find: /^\.\/panelHttp$/, replacement: workspace },
    { find: 'firebase/firestore', replacement: path.resolve(__dirname, 'fixtures/firestore.ts') },
    { find: '@', replacement: path.join(root, 'src') },
  ] },
});
