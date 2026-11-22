/**
 * Rendering the backend's timestamps, which are NOT all ISO strings.
 *
 * Postgres `timestamp` columns come back through Drizzle's `mode: 'string'` as
 * `YYYY-MM-DD HH:MM:SS[.ffffff]` — a space instead of the `T`, and NO zone suffix. `new Date()`
 * parses that shape as LOCAL time, while the value is UTC, so every such column renders shifted by
 * the viewer's offset: west of UTC a row created just after midnight shows the previous day, and
 * "held since" on the Reserved Identifiers page reads as a date that has not happened yet in Asia.
 * Values that already carry a zone (`Z`, `+01:00`) or a `T` are left exactly as they are — those
 * come from `new Date().toISOString()` on the server and are already unambiguous.
 *
 * One module rather than a fix at each call site: the rule is a property of the TRANSPORT and not
 * of any one page, so every surface that renders a backend timestamp needs it — the admin site's
 * four such pages and the ecosystem panes alike — and a page that forgets it is wrong in a way
 * nobody notices until a bug report from another timezone.
 */

/**
 * Postgres's own text for a timestamp: `YYYY-MM-DD HH:MM:SS[.ffffff]`, then for a `timestamptz`
 * column its offset as `+HH`, `+HH:MM` or `+HHMM`. Captured as date, time, fraction, offset hours,
 * offset minutes.
 */
const POSTGRES = /^(\d{4}-\d{2}-\d{2})[ T](\d{2}:\d{2}:\d{2})(?:\.(\d+))?(?:([+-]\d{2})(?::?(\d{2}))?)?$/;

/**
 * The ECMAScript date-time format for a backend timestamp, which is the only shape every engine
 * must parse. V8 is lenient and reads Postgres's text as it comes; Safari and Firefox are not, and
 * answer Invalid Date for the space separator, the two-digit `+00` offset and a fraction longer
 * than milliseconds. So the text is rewritten to `YYYY-MM-DDTHH:MM:SS.sss±HH:MM` (a zone-less
 * value gets `Z`, per the module note) before `Date` sees it. Anything else passes through.
 */
function toIso(value: string): string {
  const m = POSTGRES.exec(value);
  if (!m) return value;
  const [, date, time, fraction, offsetHours, offsetMinutes] = m;
  const ms = fraction ? `.${fraction.slice(0, 3).padEnd(3, "0")}` : "";
  const zone = offsetHours ? `${offsetHours}:${offsetMinutes ?? "00"}` : "Z";
  return `${date}T${time}${ms}${zone}`;
}

/** A `Date` for a backend timestamp, or null when the value is not a timestamp at all. */
export function parseBackendTimestamp(value: string): Date | null {
  const d = new Date(toIso(value));
  return Number.isNaN(d.getTime()) ? null : d;
}

/**
 * A date, in the viewer's locale. `fallback` is returned for anything unparseable — showing the raw
 * value would be noise in a narrow column, and "Invalid Date" is worse than an em dash.
 */
export function formatDate(value: string | null | undefined, fallback = "—"): string {
  if (!value) return fallback;
  const d = parseBackendTimestamp(value);
  return d ? d.toLocaleDateString() : fallback;
}

/** A date and time, in the viewer's locale. Unparseable values fall back to the raw string, which
 *  in a wide column is more useful to an operator than an em dash. */
export function formatDateTime(value: string | null | undefined, fallback = "—"): string {
  if (!value) return fallback;
  const d = parseBackendTimestamp(value);
  return d ? d.toLocaleString(undefined, { dateStyle: "medium", timeStyle: "short" }) : value;
}
