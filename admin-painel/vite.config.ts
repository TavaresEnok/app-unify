import path from "path"
import react from "@vitejs/plugin-react"
import { defineConfig } from "vite"

export default defineConfig({
  base: "./",
  plugins: [react()],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
  build: {
    outDir: 'dist_final',
    chunkSizeWarningLimit: 600,
    rollupOptions: {
      output: {
        manualChunks(id) {
          if (!id.includes('node_modules')) return undefined
          if (id.includes('/react-dom/') || id.includes('/react-router-dom/') || id.includes('/react/')) return 'react'
          if (id.includes('/@firebase/auth') || id.includes('/firebase/auth')) return 'firebase-auth'
          if (id.includes('/@firebase/firestore') || id.includes('/firebase/firestore')) return 'firebase-firestore'
          if (id.includes('/@firebase/storage') || id.includes('/firebase/storage')) return 'firebase-storage'
          if (id.includes('/@firebase/functions') || id.includes('/firebase/functions')) return 'firebase-functions'
          if (id.includes('/@firebase/')) return 'firebase-core'
          if (id.includes('/recharts/')) return 'charts'
          if (id.includes('/@tiptap/') || id.includes('/prosemirror-')) return 'editor'
          return undefined
        },
      },
    },
  },
})
