import { defineConfig } from 'vitest/config';
export default defineConfig({ test: { include: ['benchmarks/capacity.test.ts'], maxWorkers: 1, testTimeout: 120000 } });
