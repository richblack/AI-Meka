import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // Workspace with two projects: unit (fast, Node) and integration (Miniflare).
    // Select via `vitest run --project unit` or `--project integration`.
    projects: [
      {
        extends: true,
        test: {
          name: 'unit',
          include: ['tests/unit/**/*.test.ts'],
          environment: 'node',
          globals: false,
        },
      },
      {
        extends: true,
        test: {
          name: 'integration',
          include: ['tests/integration/**/*.test.ts'],
          // When project uses Cloudflare Workers, switch to the workers pool:
          //
          //   pool: '@cloudflare/vitest-pool-workers',
          //   poolOptions: {
          //     workers: {
          //       wrangler: { configPath: './wrangler.toml' },
          //     },
          //   },
          //
          // For non-Workers projects, default Node pool with Miniflare is fine.
          environment: 'node',
          globals: false,
        },
      },
    ],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html', 'json-summary'],
      include: ['src/**/*.ts'],
      exclude: ['src/**/*.d.ts', 'src/**/*.test.ts'],
      thresholds: {
        lines: 70,
        functions: 70,
        branches: 60,
        statements: 70,
      },
    },
  },
});
