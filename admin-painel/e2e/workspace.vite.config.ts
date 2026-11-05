import path from 'node:path';
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
const root = path.resolve(__dirname, '..');
const workspace = path.resolve(__dirname, 'fixtures/workspace.tsx');
export default defineConfig({
  root,
  plugins: [react()],
  resolve: { alias: [
    ...['@/contexts/AuthContext', '@/firebase/auth', '@/firebase/config', '@/hooks/useApi', '@/shared/firebase/providerSettingsService', '@/features/providers/providerService'].map(find => ({ find, replacement: workspace })),
    { find: 'firebase/firestore', replacement: path.resolve(__dirname, 'fixtures/firestore.ts') },
    { find: '@', replacement: path.join(root, 'src') },
  ] },
});
