import { describe, it, expect, afterEach, vi } from 'vitest';
import {
  subscribeLive,
  publishSnapshot,
  recentSnapshot,
  liveSubscriberCount,
  resetLiveEvents,
  emitLiveUpdate,
} from '../src/live/live-events';
import { buildLiveSnapshot } from '../src/routes/reads';
import type { StatusConfig } from '../src/config/port';
import type { Storage } from '../src/storage/ports';
import type { LiveSnapshot } from '../src/monitor/live-types';
import { liveSnapshot } from './helpers/snapshot';

vi.mock('../src/routes/reads', () => ({ buildLiveSnapshot: vi.fn() }));
const buildMock = vi.mocked(buildLiveSnapshot);

const snap = (generatedAt: string): LiveSnapshot => liveSnapshot({ generatedAt });

describe('live-events pub/sub', () => {
  afterEach(() => resetLiveEvents());

  it('fans one published snapshot out to every subscriber', () => {
    const a: LiveSnapshot[] = [];
    const b: LiveSnapshot[] = [];
    subscribeLive((s) => a.push(s));
    subscribeLive((s) => b.push(s));
    expect(liveSubscriberCount()).toBe(2);

    const s = snap('2026-06-30T00:00:00.000Z');
    publishSnapshot(s);

    // The SAME object reaches every subscriber — one build, N deliveries.
    expect(a).toEqual([s]);
    expect(b).toEqual([s]);
    expect(a[0]).toBe(s);
    expect(b[0]).toBe(s);
  });

  it('stops delivering after unsubscribe', () => {
    const got: LiveSnapshot[] = [];
    const off = subscribeLive((s) => got.push(s));
    publishSnapshot(snap('1'));
    off();
    publishSnapshot(snap('2'));
    expect(got.map((s) => s.generatedAt)).toEqual(['1']);
    expect(liveSubscriberCount()).toBe(0);
  });

  it('a throwing subscriber never blocks the fan-out to the others', () => {
    const got: string[] = [];
    subscribeLive(() => {
      throw new Error('boom');
    });
    subscribeLive((s) => got.push(s.generatedAt));
    publishSnapshot(snap('ok'));
    expect(got).toEqual(['ok']);
  });

  it('recentSnapshot serves the last published snapshot within the age window, else null', () => {
    vi.useFakeTimers();
    try {
      expect(recentSnapshot(1000)).toBeNull(); // nothing published yet
      const s = snap('2026-06-30T00:00:00.000Z');
      publishSnapshot(s);
      expect(recentSnapshot(1000)).toBe(s); // fresh
      vi.advanceTimersByTime(1500);
      expect(recentSnapshot(1000)).toBeNull(); // aged out
    } finally {
      vi.useRealTimers();
    }
  });
});

// Conformance vectors for cookbook/status/service/live-events — one test per vector id.
describe('live-events conformance vectors', () => {
  const config = {} as StatusConfig;
  /** A Storage whose every method throws, to prove emit never touches it when idle. */
  const throwingStorage = new Proxy(
    {},
    {
      get: () => {
        throw new Error('storage must not be touched');
      },
    },
  ) as unknown as Storage;
  const storage = {} as Storage;

  afterEach(() => {
    resetLiveEvents();
    buildMock.mockReset();
    vi.useRealTimers();
    vi.restoreAllMocks();
  });

  it('status-server-live-001 two subscribers register', () => {
    subscribeLive(() => {});
    subscribeLive(() => {});
    expect(liveSubscriberCount()).toBe(2);
  });

  it('status-server-live-002 unsubscribe stops delivery and drops the count', () => {
    const cb = vi.fn();
    const off = subscribeLive(cb);
    off();
    publishSnapshot(snap('x'));
    expect(cb).not.toHaveBeenCalled();
    expect(liveSubscriberCount()).toBe(0);
  });

  it('status-server-live-003 every subscriber gets the same object reference', () => {
    const a: LiveSnapshot[] = [];
    const b: LiveSnapshot[] = [];
    subscribeLive((x) => a.push(x));
    subscribeLive((x) => b.push(x));
    const s = snap('3');
    publishSnapshot(s);
    expect(a).toEqual([s]);
    expect(b).toEqual([s]);
    expect(a[0]).toBe(s);
    expect(b[0]).toBe(s);
  });

  it('status-server-live-004 a throwing subscriber is isolated and logged', () => {
    const err = vi.spyOn(console, 'error').mockImplementation(() => {});
    const got: LiveSnapshot[] = [];
    subscribeLive(() => {
      throw new Error('boom');
    });
    subscribeLive((x) => got.push(x));
    const s = snap('4');
    expect(() => publishSnapshot(s)).not.toThrow();
    expect(got).toEqual([s]);
    expect(err).toHaveBeenCalledTimes(1);
  });

  it('status-server-live-005 publish with zero subscribers still caches', () => {
    expect(liveSubscriberCount()).toBe(0);
    const s = snap('5');
    publishSnapshot(s);
    expect(recentSnapshot(60_000)).toBe(s);
  });

  it('status-server-live-006 recentSnapshot is null before any publish', () => {
    vi.useFakeTimers();
    expect(recentSnapshot(1000)).toBeNull();
  });

  it('status-server-live-007 recentSnapshot returns the fresh snapshot by reference', () => {
    vi.useFakeTimers();
    const s = snap('7');
    publishSnapshot(s);
    expect(recentSnapshot(1000)).toBe(s);
  });

  it('status-server-live-008 recentSnapshot is null once aged past the window', () => {
    vi.useFakeTimers();
    publishSnapshot(snap('8'));
    vi.advanceTimersByTime(1500);
    expect(recentSnapshot(1000)).toBeNull();
  });

  it('status-server-live-009 reset clears subscribers and the cache', () => {
    subscribeLive(() => {});
    subscribeLive(() => {});
    publishSnapshot(snap('9'));
    resetLiveEvents();
    expect(liveSubscriberCount()).toBe(0);
    expect(recentSnapshot(60_000)).toBeNull();
  });

  it('status-server-live-010 emit with no subscribers touches nothing and schedules nothing', () => {
    vi.useFakeTimers();
    emitLiveUpdate(throwingStorage, config);
    expect(buildMock).not.toHaveBeenCalled();
    expect(vi.getTimerCount()).toBe(0);
  });

  it('status-server-live-011 three same-tick emits coalesce into one build and one delivery', async () => {
    vi.useFakeTimers();
    const s = snap('11');
    buildMock.mockResolvedValue(s);
    const got: LiveSnapshot[] = [];
    subscribeLive((x) => got.push(x));
    emitLiveUpdate(storage, config);
    emitLiveUpdate(storage, config);
    emitLiveUpdate(storage, config);
    await vi.advanceTimersByTimeAsync(150);
    expect(buildMock).toHaveBeenCalledTimes(1);
    expect(buildMock).toHaveBeenCalledWith(storage, config);
    expect(got).toEqual([s]);
  });

  it('status-server-live-012 a rejected build is logged, never delivered, never thrown', async () => {
    vi.useFakeTimers();
    const err = vi.spyOn(console, 'error').mockImplementation(() => {});
    buildMock.mockRejectedValue(new Error('db down'));
    const cb = vi.fn();
    subscribeLive(cb);
    expect(() => emitLiveUpdate(storage, config)).not.toThrow();
    await vi.advanceTimersByTimeAsync(150);
    expect(buildMock).toHaveBeenCalledTimes(1);
    expect(err).toHaveBeenCalledTimes(1);
    expect(cb).not.toHaveBeenCalled();
  });

  it('status-server-live-013 reset before the window elapses cancels the armed build', async () => {
    vi.useFakeTimers();
    buildMock.mockResolvedValue(snap('13'));
    subscribeLive(() => {});
    emitLiveUpdate(storage, config);
    resetLiveEvents();
    await vi.advanceTimersByTimeAsync(500);
    expect(buildMock).not.toHaveBeenCalled();
  });
});
