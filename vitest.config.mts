import { fileURLToPath } from 'node:url';
import functionsConfig from './functions/vitest.config.mts';

// npm --prefix functions exec keeps the caller's cwd. Reuse the complete
// package config, resolving its root independently of the invocation directory.
export default {
  ...functionsConfig,
  root: fileURLToPath(new URL('./functions/', import.meta.url)),
};
