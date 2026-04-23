import { describe, it, expect } from 'vitest';

// Example unit test. Replace with your own.
// AI-Meka convention: every task in tasks.md declares a Test File like this one,
// and the task may only be marked [x] after this file runs green.

describe('example unit', () => {
  it('adds two numbers', () => {
    expect(1 + 1).toBe(2);
  });

  it('handles async work', async () => {
    const value = await Promise.resolve('hello');
    expect(value).toBe('hello');
  });
});
