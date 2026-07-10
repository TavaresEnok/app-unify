/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_API_URL?: string;
  readonly VITE_APK_BUILDER_URL?: string;
  readonly VITE_DOWNLOADS_URL?: string;
  readonly VITE_PANEL_URL?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
