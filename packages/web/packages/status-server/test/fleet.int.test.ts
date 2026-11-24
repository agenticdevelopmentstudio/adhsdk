import { describe, it, expect, beforeAll } from 'vitest';
import { createClient } from '@libsql/client';
import { drizzle } from 'drizzle-orm/libsql';
import { migrate } from 'drizzle-orm/libsql/migrator';
import * as schema from '../src/libsql/schema';
import { createApp } from '../src/app';
import { testDeps } from './helpers/storage';
import type { Db } from '../src/libsql/client';
import { sessionHeaders } from './helpers/auth';
import { MIGRATIONS_FOLDER } from '../src/libsql/client';
import { testConfig } from './helpers/config';
import { assembleFleet } from '../src/peers/fleet';
import { createLibsqlStorage } from '../src/libsql';
import { freshDb } from './helpers/db';

describe('/fleet', () => {
  let app: ReturnType<typeof createApp>;
  let viewAuth: { Cookie: string };

  beforeAll(async () => {
    const db: Db = drizzle(createClient({ url: ':memory:' }), { schema });
    await migrate(db, { migrationsFolder: MIGRATIONS_FOLDER });
    viewAuth = await sessionHeaders(db, 'viewer');
    const p = (await db.insert(schema.peers).values({ label: 'B', baseUrl: 'https://b.example.com' }).returning())[0];
    await db.insert(schema.peerSnapshots).values({ peerId: p!.id, overall: 'down', reachable: true, payload: { overall: 'down' } });
    // A deactivated peer that still has a snapshot on file — nobody polls it any more,
    // so that snapshot is frozen and must not be drawn on the board.
    const off = (
      await db
        .insert(schema.peers)
        .values({ label: 'Off', baseUrl: 'https://off.example.com', isActive: false })
        .returning()
    )[0];
    await db.insert(schema.peerSnapshots).values({ peerId: off!.id, overall: 'ok', reachable: true, payload: { overall: 'ok' } });
    app = createApp(testDeps(db));
  });

  it('returns self + peer members', async () => {
    const res = await app.request('/fleet', { headers: viewAuth });
    expect(res.status).toBe(200);
    const members = (await res.json()) as Array<{ self: boolean; overall: string | null }>;
    expect(members.some((m) => m.self)).toBe(true);
    expect(members.some((m) => !m.self && m.overall === 'down')).toBe(true);
  });

  it('omits inactive peers — an unpolled peer must not show a frozen card', async () => {
    const res = await app.request('/fleet', { headers: viewAuth });
    const members = (await res.json()) as Array<{ self: boolean; label: string }>;
    expect(members.map((m) => m.label)).not.toContain('Off');
  });

  it('401 without a token', async () => {
    expect((await app.request('/fleet')).status).toBe(401);
  });
});

describe('assembleFleet', () => {
  const self = { label: 'lewis', snapshot: { status: 'ok' }, overall: 'healthy' };

  it('status-server-peers-015 returns just the self member when there are no active peers', async () => {
    const db = await freshDb();
    const members = await assembleFleet(createLibsqlStorage(db), self);
    expect(members).toHaveLength(1);
    expect(members[0]).toMatchObject({
      self: true,
      baseUrl: null,
      reachable: true,
      label: 'lewis',
      overall: 'healthy',
      payload: { status: 'ok' },
    });
  });

  it('status-server-peers-016 defaults an active peer with no snapshot and excludes inactive peers', async () => {
    const db = await freshDb();
    await db.insert(schema.peers).values({ label: 'A', baseUrl: 'https://a.example.com' });
    const off = (
      await db.insert(schema.peers).values({ label: 'Off', baseUrl: 'https://off.example.com', isActive: false }).returning()
    )[0]!;
    await db.insert(schema.peerSnapshots).values({ peerId: off.id, overall: 'ok', reachable: true, payload: { overall: 'ok' } });
    const members = await assembleFleet(createLibsqlStorage(db), self);
    expect(members).toHaveLength(2);
    expect(members[1]).toMatchObject({
      self: false,
      label: 'A',
      baseUrl: 'https://a.example.com',
      overall: null,
      reachable: false,
      payload: null,
      fetchedAt: new Date(0).toISOString(),
    });
    expect(members.map((m) => m.label)).not.toContain('Off');
  });

  it("status-server-peers-017 matches each peer to its own snapshot only", async () => {
    const db = await freshDb();
    const inserted = (
      await db
        .insert(schema.peers)
        .values([
          { label: 'P1', baseUrl: 'https://p1.example.com' },
          { label: 'P2', baseUrl: 'https://p2.example.com' },
        ])
        .returning()
    );
    const [p1, p2] = [inserted[0]!, inserted[1]!];
    expect(p1.id).not.toBe(p2.id);
    await db.insert(schema.peerSnapshots).values({ peerId: p2.id, overall: 'down', reachable: true, payload: { overall: 'down' } });
    const members = await assembleFleet(createLibsqlStorage(db), self);
    const byLabel = (l: string) => members.find((m) => m.label === l)!;
    expect(byLabel('P1')).toMatchObject({ overall: null, reachable: false, fetchedAt: new Date(0).toISOString() });
    expect(byLabel('P2')).toMatchObject({ overall: 'down', reachable: true, payload: { overall: 'down' } });
  });
});
