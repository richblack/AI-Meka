import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { Miniflare } from 'miniflare';

// Example integration test driven by Miniflare — a local Workers runtime.
// Useful when your project deploys to Cloudflare Workers: run against a KV /
// R2 / Durable Object backed by in-memory Miniflare, without touching
// production.
//
// For non-Workers projects, use the Node pool directly and spin up your HTTP
// server via `createServer(...)` or Testcontainers instead.

describe('example miniflare integration', () => {
  let mf: Miniflare;

  beforeAll(async () => {
    mf = new Miniflare({
      modules: true,
      script: `
        export default {
          async fetch(request, env) {
            const url = new URL(request.url);
            if (url.pathname === '/ping') {
              return new Response('pong', { status: 200 });
            }
            if (url.pathname === '/kv-echo') {
              await env.KV.put('greeting', 'hello');
              const value = await env.KV.get('greeting');
              return Response.json({ value });
            }
            return new Response('not found', { status: 404 });
          },
        };
      `,
      kvNamespaces: ['KV'],
    });
  });

  afterAll(async () => {
    await mf?.dispose();
  });

  it('responds to /ping', async () => {
    const res = await mf.dispatchFetch('http://localhost/ping');
    expect(res.status).toBe(200);
    expect(await res.text()).toBe('pong');
  });

  it('round-trips a KV value', async () => {
    const res = await mf.dispatchFetch('http://localhost/kv-echo');
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ value: 'hello' });
  });
});
