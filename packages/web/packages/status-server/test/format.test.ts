import { describe, it, expect, vi, afterEach } from 'vitest';
import { commitFirstLine, commitFullMessage, shortSha } from '../src/monitor/format';

afterEach(() => vi.restoreAllMocks());

describe('commitFullMessage', () => {
  it('returns null for empty input', () => {
    expect(commitFullMessage(null)).toBeNull();
    expect(commitFullMessage(undefined)).toBeNull();
    expect(commitFullMessage('')).toBeNull();
    expect(commitFullMessage('   \n  ')).toBeNull();
  });

  it('keeps the whole message including body newlines', () => {
    expect(commitFullMessage('subject')).toBe('subject');
    expect(commitFullMessage('subject\n\nbody line 1\nbody line 2')).toBe('subject\n\nbody line 1\nbody line 2');
  });

  it('strips trailing whitespace but not internal newlines', () => {
    expect(commitFullMessage('subject\n\nbody\n\n')).toBe('subject\n\nbody');
  });

  it('caps at max chars', () => {
    expect(commitFullMessage('x'.repeat(50), 10)).toBe('x'.repeat(10));
  });
});

// Conformance vectors for cookbook/status/service/monitor/format.
describe('format conformance vectors', () => {
  it('status-server-monitor-format-001: commitFullMessage answers null for null, undefined and empty', () => {
    expect(commitFullMessage(null)).toBeNull();
    expect(commitFullMessage(undefined)).toBeNull();
    expect(commitFullMessage('')).toBeNull();
  });

  it('status-server-monitor-format-002: commitFullMessage answers null for whitespace only', () => {
    expect(commitFullMessage('   \n  ')).toBeNull();
  });

  it('status-server-monitor-format-003: commitFullMessage preserves internal newlines', () => {
    expect(commitFullMessage('subject')).toBe('subject');
    expect(commitFullMessage('subject\n\nbody line 1\nbody line 2')).toBe('subject\n\nbody line 1\nbody line 2');
  });

  it('status-server-monitor-format-004: commitFullMessage strips trailing newlines only', () => {
    expect(commitFullMessage('subject\n\nbody\n\n')).toBe('subject\n\nbody');
  });

  it('status-server-monitor-format-005: commitFullMessage caps at max', () => {
    expect(commitFullMessage('x'.repeat(50), 10)).toBe('x'.repeat(10));
    expect(commitFullMessage('x'.repeat(4500))).toBe('x'.repeat(4000));
  });

  it('status-server-monitor-format-006: shortSha keeps the first 7 characters', () => {
    expect(shortSha('abcdef1234567890')).toBe('abcdef1');
  });

  it('status-server-monitor-format-007: shortSha answers null for null, undefined and empty', () => {
    expect(shortSha(null)).toBeNull();
    expect(shortSha(undefined)).toBeNull();
    expect(shortSha('')).toBeNull();
  });

  it('status-server-monitor-format-008: shortSha does not validate or pad a short value', () => {
    expect(shortSha('ab')).toBe('ab');
  });

  it('status-server-monitor-format-009: commitFirstLine takes the text before the first newline', () => {
    expect(commitFirstLine('subject\n\nbody')).toBe('subject');
  });

  it('status-server-monitor-format-010: commitFirstLine answers null for null, undefined and empty', () => {
    expect(commitFirstLine(null)).toBeNull();
    expect(commitFirstLine(undefined)).toBeNull();
    expect(commitFirstLine('')).toBeNull();
  });

  it('status-server-monitor-format-011: commitFirstLine caps at the default 200', () => {
    expect(commitFirstLine('x'.repeat(250))).toBe('x'.repeat(200));
  });

  it('status-server-monitor-format-012: commitFirstLine does not trim', () => {
    expect(commitFirstLine('  leading and trailing  ')).toBe('  leading and trailing  ');
  });

  it('status-server-monitor-format-013: all three are pure, synchronous and never throw', () => {
    const fetchSpy = vi.fn();
    vi.stubGlobal('fetch', fetchSpy);
    const spies = [
      vi.spyOn(console, 'log').mockImplementation(() => {}),
      vi.spyOn(console, 'error').mockImplementation(() => {}),
      vi.spyOn(console, 'warn').mockImplementation(() => {}),
      vi.spyOn(console, 'info').mockImplementation(() => {}),
      vi.spyOn(console, 'debug').mockImplementation(() => {}),
    ];
    try {
      const inputs: Array<string | null | undefined> = [
        null,
        undefined,
        '',
        '   \n  ',
        'subject',
        'subject\n\nbody line 1\nbody line 2',
        'subject\n\nbody\n\n',
        'x'.repeat(250),
        'abcdef1234567890',
        'ab',
        '  leading and trailing  ',
      ];
      for (const input of inputs) {
        expect(() => shortSha(input)).not.toThrow();
        expect(() => commitFirstLine(input)).not.toThrow();
        expect(() => commitFullMessage(input)).not.toThrow();
        // Synchronous: the result is a plain value, not a promise.
        expect(shortSha(input)).not.toBeInstanceOf(Promise);
      }
      expect(() => commitFullMessage('x'.repeat(50), 10)).not.toThrow();
      expect(fetchSpy).not.toHaveBeenCalled();
      for (const s of spies) expect(s).not.toHaveBeenCalled();
    } finally {
      vi.unstubAllGlobals();
    }
  });
});
