import { describe, it, expect } from 'vitest';
import * as schema from '../src/libsql/schema';
import { fetchPeers } from '../src/peers/fetch';
import { createLibsqlStorage } from '../src/libsql';
import { freshDb } from './helpers/db';

describe('fetchPeers', () => {
  it('status-server-peers-011 stores a reachable peer snapshot', async () => {
    const db = await freshDb();
    await db.insert(schema.peers).values({ label: 'B', baseUrl: 'https://b.example.com', token: 't' });
    const fakeFetch = async () => new Response(JSON.stringify({ overall: 'healthy' }), { status: 200 });
    await fetchPeers(createLibsqlStorage(db), fakeFetch as unknown as typeof fetch);
    const snap = await db.select().from(schema.peerSnapshots);
    expect(snap[0]!.reachable).toBe(true);
    expect(snap[0]!.overall).toBe('healthy');
  });

  it('status-server-peers-012 records an unreachable peer without throwing', async () => {
    const db = await freshDb();
    await db.insert(schema.peers).values({ label: 'B', baseUrl: 'https://b.example.com' });
    const failFetch = async () => {
      throw new Error('ECONNREFUSED');
    };
    await expect(fetchPeers(createLibsqlStorage(db), failFetch as unknown as typeof fetch)).resolves.toBeUndefined();
    const snap = await db.select().from(schema.peerSnapshots);
    expect(snap[0]!.reachable).toBe(false);
    expect(snap[0]!.error).toContain('ECONNREFUSED');
  });

  it('status-server-peers-013 sends no Authorization header for a peer without a token', async () => {
    const db = await freshDb();
    await db.insert(schema.peers).values({ label: 'B', baseUrl: 'https://b.example.com', token: null });
    const calls: { url: string; init: RequestInit }[] = [];
    const capture = async (url: string, init: RequestInit): Promise<Response> => {
      calls.push({ url, init });
      return new Response('{}', { status: 200 });
    };
    await fetchPeers(createLibsqlStorage(db), capture as unknown as typeof fetch);
    expect(calls).toHaveLength(1);
    expect(calls[0]!.url).toBe('https://b.example.com/snapshot');
    expect(Object.keys(calls[0]!.init.headers as Record<string, string>)).not.toContain('Authorization');
  });

  it('status-server-peers-014 turns a non-ok HTTP response into an unreachable snapshot', async () => {
    const db = await freshDb();
    await db.insert(schema.peers).values({ label: 'B', baseUrl: 'https://b.example.com' });
    const bad = async () => new Response('bad gateway', { status: 502 });
    await fetchPeers(createLibsqlStorage(db), bad as unknown as typeof fetch);
    const snap = await db.select().from(schema.peerSnapshots);
    expect(snap[0]!.reachable).toBe(false);
    expect(snap[0]!.error).toContain('HTTP 502');
  });

  it('status-server-peers-019 stores a peer payload unvalidated', async () => {
    const db = await freshDb();
    await db.insert(schema.peers).values({ label: 'B', baseUrl: 'https://b.example.com' });
    const odd = async () => new Response(JSON.stringify({ overall: 42 }), { status: 200 });
    await expect(fetchPeers(createLibsqlStorage(db), odd as unknown as typeof fetch)).resolves.toBeUndefined();
    const snap = await db.select().from(schema.peerSnapshots);
    expect(snap[0]!.reachable).toBe(true);
    expect(snap[0]!.error).toBeNull();
    // Not rejected or coerced by fetchPeers: the raw payload is kept as sent, and the
    // `overall` TEXT column's affinity is what turns the number into "42.0" on read-back.
    expect(snap[0]!.payload).toEqual({ overall: 42 });
    expect(snap[0]!.overall).toBe('42.0');
  });
});
