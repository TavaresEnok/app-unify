import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    include: ['src/**/*.test.ts'],
    maxWorkers: 2,
    coverage: {
      provider: 'v8',
      include: ['src/app/**/*.ts', 'src/contracts/index.ts', 'src/handlers/**/*.ts', 'src/utils.ts'],
      exclude: ['src/**/*.test.ts'],
      thresholds: { branches: 20, functions: 34, lines: 40, statements: 39 },
    },
  },
});
