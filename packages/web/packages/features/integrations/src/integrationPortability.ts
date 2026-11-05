/**
 * THE EXPORT DOCUMENT — what an integration is when it is a file rather than a row.
 *
 * Pure functions from data to data, deliberately: every browser-facing part of export and import
 * (the save dialog, the file picker, the reading of a `File`) is `@adh-sdk/ui`'s
 * `lib/file-exchange`, and everything here can be tested by handing it rows and reading back a
 * string. The pane composes the two.
 *
 * SECRETS ARE NOT IN THE DOCUMENT, and this is the whole design constraint rather than an
 * oversight. The API answers with a `MaskedProviderConfig` and has never echoed a stored secret
 * back — `hasSecret` is a boolean, not a value — so an export that carried them would need a new
 * reveal endpoint, which is a security decision and not one this file gets to take on its own.
 * What the document carries instead is `needsSecrets`: the operator-facing NAME of each
 * credential the import will have to be given again ("Private key", "API token"). An import that
 * silently creates half-configured integrations and says nothing is the failure that avoids.
 */

import type { MaskedProviderConfig, ProviderCatalogEntry } from "@adh-sdk/data/integrations";

import {
  credentialShape,
  hasConfigFields,
  intToInput,
  type IntegrationInput,
} from "./IntegrationDetail";

/** The document's self-declared type. Checked on import so a JSON file that is merely VALID —
 *  a package.json, someone's API response — is refused by name rather than half-applied. */
export const EXPORT_KIND = "adh.integrations";
/** Bumped when a reader would get the wrong answer from an older document, never for an added
 *  optional field. Import refuses a version it does not know rather than guessing. */
export const EXPORT_VERSION = 1;

export interface ExportedIntegration {
  providerId: string;
  /** The instance name. Half of the duplicate identity — see {@link splitImport}. */
  name: string;
  /** The editor's own draft shape, which is what makes the round trip exact: export is
   *  `intToInput`, import is `intToCreateBody`, and the pair is already what the detail view
   *  saves through. Every secret field in it is blank. */
  input: IntegrationInput;
  /** What the operator has to re-enter, by the label the form will ask for it under. Empty when
   *  this integration stored no secret at all. */
  needsSecrets: string[];
}

export interface IntegrationsExport {
  kind: typeof EXPORT_KIND;
  version: number;
  /** ISO-8601. Informational — nothing reads it back — so that a file found in a downloads
   *  folder a month later says when it was true. */
  exportedAt: string;
  integrations: ExportedIntegration[];
}

/** The names of the credentials this row stores and the document cannot carry. */
function secretsOf(row: MaskedProviderConfig, provider?: ProviderCatalogEntry): string[] {
  if (hasConfigFields(provider)) {
    // A configField provider's secrets are declared, so the labels are the spec's own words —
    // the same ones the import's form will print above the empty box.
    return (provider?.configFields ?? []).filter((f) => f.secret).map((f) => f.label);
  }
  // Everything else has at most the one, and `hasSecret` is the only thing that knows whether it
  // is actually set: a provider that COULD take a client secret and was configured without one
  // must not tell the importer to go and find a secret that never existed.
  return row.hasSecret ? [credentialShape(provider?.authMethod).secretLabel] : [];
}

/**
 * The document for these rows, in the order they were given.
 *
 * `providerById` is the catalog, and a row whose provider is missing from it is still exported:
 * `intToInput` degrades to the OAuth-shaped read, which is exactly the fields the config
 * actually holds, and refusing to export a row because this deployment's catalog has moved on
 * would lose the one copy of it the operator was trying to keep.
 */
export function buildExport(
  rows: readonly MaskedProviderConfig[],
  providerById: ReadonlyMap<string, ProviderCatalogEntry>,
  now: Date = new Date(),
): IntegrationsExport {
  return {
    kind: EXPORT_KIND,
    version: EXPORT_VERSION,
    exportedAt: now.toISOString(),
    integrations: rows.map((row) => {
      const provider = providerById.get(row.providerId);
      return {
        providerId: row.providerId,
        name: row.name,
        input: intToInput(row, provider),
        needsSecrets: secretsOf(row, provider),
      };
    }),
  };
}

/** Pretty-printed, with a trailing newline: this file is meant to be opened, read, diffed and
 *  kept in a repository, not only handed back to this console. */
export function serializeExport(doc: IntegrationsExport): string {
  return `${JSON.stringify(doc, null, 2)}\n`;
}

/** `integrations-2026-09-12.json`. Dated rather than timestamped, because two exports on the same
 *  day are the same day's configuration and the browser will number the second one itself.
 *
 *  The operator's OWN date, not UTC's. A name is read by the person who saved it, in a downloads
 *  folder sorted by the same clock their machine shows, and west of Greenwich an evening export
 *  came out named tomorrow — so two exports taken either side of their own midnight sorted the
 *  wrong way round against every other file in the folder. */
export function exportFilename(now: Date = new Date()): string {
  const pad = (n: number) => String(n).padStart(2, "0");
  const day = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}`;
  return `integrations-${day}.json`;
}

/**
 * Read a document back, or throw a sentence the operator can act on.
 *
 * Every refusal names what was wrong with THE FILE. "Unexpected token < in JSON at position 0" is
 * what happens when somebody picks an HTML page by mistake, and it tells them nothing about which
 * of the three things they did wrong.
 */
export function parseExport(text: string): IntegrationsExport {
  let raw: unknown;
  try {
    raw = JSON.parse(text);
  } catch {
    throw new Error("That file isn't JSON.");
  }
  if (typeof raw !== "object" || raw === null || Array.isArray(raw)) {
    throw new Error("That file isn't an integrations export.");
  }
  const doc = raw as Partial<IntegrationsExport>;
  if (doc.kind !== EXPORT_KIND) {
    throw new Error("That file isn't an integrations export.");
  }
  if (doc.version !== EXPORT_VERSION) {
    throw versionRefusal(doc.version);
  }
  if (!Array.isArray(doc.integrations)) {
    throw new Error("That export has no integrations in it.");
  }
  const integrations = doc.integrations.filter(isExportedIntegration);
  if (integrations.length !== doc.integrations.length) {
    throw new Error("That export is damaged — some of its integrations are unreadable.");
  }
  return { kind: EXPORT_KIND, version: EXPORT_VERSION, exportedAt: doc.exportedAt ?? "", integrations };
}

/**
 * Why the version was refused, in the operator's terms.
 *
 * Three different situations, and one of them used to speak for all three: a document with no
 * version at all, or one written before this format, was reported as "written by a NEWER version
 * of the console (format undefined)" — advice to go and upgrade something that would not have
 * helped, about a file whose actual problem was that it was damaged or old.
 */
function versionRefusal(version: unknown): Error {
  if (typeof version !== "number" || !Number.isInteger(version)) {
    return new Error("That export doesn't say which format it is written in.");
  }
  if (version > EXPORT_VERSION) {
    return new Error(
      `That export was written by a newer version of the console (format ${version}).`,
    );
  }
  return new Error(`That export is in format ${version}, which this console can no longer read.`);
}

/** The `credentialStyle` union, as data — a string that is not one of these is not the field. */
const CREDENTIAL_STYLES: readonly IntegrationInput["credentialStyle"][] = [
  "",
  "form_body",
  "basic_auth",
];

/** Every text field {@link IntegrationInput} declares. */
const INPUT_TEXT_FIELDS = [
  "providerId",
  "name",
  "clientId",
  "clientSecret",
  "scopes",
  "authUrl",
  "tokenUrl",
  "userinfoUrl",
  "validateUrl",
] as const;

function isStringMap(v: unknown): v is Record<string, string> {
  if (typeof v !== "object" || v === null || Array.isArray(v)) return false;
  return Object.values(v).every((s) => typeof s === "string");
}

/**
 * THE WHOLE DRAFT, not the two fields the report happened to print.
 *
 * `intToCreateBody` reads every one of these and trims most of them, so an entry that carried
 * only `providerId` passed the old guard, reached the create, and came back as
 * `"acme: Cannot read properties of undefined (reading 'trim')"` — a TypeError with an
 * integration's name in front of it, in a list the operator was reading to find out what went
 * wrong with their file. A truncated document is a damaged document and `parseExport` already
 * has the sentence for that; it just could not tell.
 */
function isIntegrationInput(v: unknown): v is IntegrationInput {
  if (typeof v !== "object" || v === null || Array.isArray(v)) return false;
  const i = v as Record<string, unknown>;
  return (
    INPUT_TEXT_FIELDS.every((k) => typeof i[k] === "string") &&
    CREDENTIAL_STYLES.includes(i.credentialStyle as IntegrationInput["credentialStyle"]) &&
    isStringMap(i.endpoints) &&
    isStringMap(i.fields) &&
    typeof i.enabled === "boolean"
  );
}

function isExportedIntegration(v: unknown): v is ExportedIntegration {
  if (typeof v !== "object" || v === null) return false;
  const e = v as Partial<ExportedIntegration>;
  return (
    typeof e.providerId === "string" &&
    typeof e.name === "string" &&
    Array.isArray(e.needsSecrets) &&
    e.needsSecrets.every((n) => typeof n === "string") &&
    isIntegrationInput(e.input) &&
    // THE TWO PROVIDER IDS ARE ONE FACT, and an entry where they disagree is refused here rather
    // than half-applied. Import reads the outer one twice — for the duplicate identity and for
    // "is this provider in our catalog" — and then POSTs the INNER one, so a hand-edited file
    // that changed only the outer id passed both checks against one provider and created a
    // config for a different one, under a name chosen to describe the first.
    e.input.providerId === e.providerId
  );
}

/**
 * WHAT THIS INTEGRATION IS, for the purpose of "have we already got it".
 *
 * The provider ALONE is not identity — multiple instances of one provider are a supported thing
 * and the whole reason a config carries a name — so it is the pair. Case- and space-insensitive,
 * because "GitHub (acme)" and "github (acme)" are the same integration to everyone except a
 * string comparison.
 */
export function identityOf(providerId: string, name: string): string {
  // JSON rather than a join, because the separator has to be one no provider id can contain and
  // a literal control character is not it: a NUL in a `.ts` file makes the whole source binary to
  // git, which then declines to diff it. `JSON.stringify` of the pair escapes whatever is inside
  // each half, so `["github-appx","a"]` and `["github-app","xa"]` stay different strings without
  // any byte being unprintable.
  return JSON.stringify([providerId, name.trim().toLowerCase()]);
}

export interface ImportSplit {
  /** Not already here, and their provider is in this catalog. */
  toCreate: ExportedIntegration[];
  /** Already here by {@link identityOf}. Ignored, and REPORTED — the operator asked for a list. */
  duplicates: ExportedIntegration[];
  /** Their provider is not in this deployment's catalog, so there is nothing to create them as.
   *  Separated from a create failure so the operator is told the reason rather than handed
   *  whatever the API says about a client id for a provider it has never heard of. */
  unknownProviders: ExportedIntegration[];
}

/**
 * Split an import into what will be created, what is already here, and what cannot be created.
 *
 * Duplicates are skipped rather than merged or overwritten. An import that overwrote would be a
 * way to lose a working credential to a stale file, and nothing in the document says which of the
 * two is newer — `exportedAt` describes the file, not the row it was taken from.
 */
export function splitImport(
  doc: IntegrationsExport,
  existing: readonly MaskedProviderConfig[],
  knownProviderIds: ReadonlySet<string>,
): ImportSplit {
  const here = new Set(existing.map((c) => identityOf(c.providerId, c.name)));
  const split: ImportSplit = { toCreate: [], duplicates: [], unknownProviders: [] };
  for (const entry of doc.integrations) {
    if (here.has(identityOf(entry.providerId, entry.name))) {
      split.duplicates.push(entry);
    } else if (!knownProviderIds.has(entry.providerId)) {
      split.unknownProviders.push(entry);
    } else {
      // Added to `here` as well, so a document that repeats an integration INSIDE ITSELF creates
      // it once and reports the rest as duplicates — which is what they are, and which the naive
      // "compare against the server's list" version silently created twice.
      here.add(identityOf(entry.providerId, entry.name));
      split.toCreate.push(entry);
    }
  }
  return split;
}
