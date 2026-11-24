// The registry's /v1 wire shapes and the field-by-field mappers between them and this
// package's exported domain types (`RegistryRow`, `EntryRow`, …), which stay stable.
//
// /v1 speaks snake_case, puts `object` on every resource and says `created` (unix seconds)
// where the domain row says `createdAt`. The gateway renames only the properties the legacy
// schema DECLARES, so the untyped maps — `values`, `valueVisibility`, `areaServed`, a field
// def's `config`, and a profile's `imageUrls` / `jsonLd` contents — keep their keys, and the
// mappers below copy them through untouched.
//
// This file takes no `@adh-sdk/auth` dependency, deliberately: `package.json` explains why
// the shipped client carries none. `isoFromUnixSeconds` is therefore this package's own
// three lines rather than `unixToIso` from `@adh-sdk/auth/client`.

import type { PublicEntry } from '@adh-sdk/registry-profile';
import type {
  EntryLink, EntryProfilePage, EntryRow, EntryWrite, FieldDefRow, RegistryRow, SectionRow,
  ServiceRow,
} from './client';

/** One /v1 collection page. */
export interface RegistryWireList<T> {
  object: 'list';
  data: T[];
  has_more: boolean;
  url: string;
}

/** The widest page /v1 serves. */
export const REGISTRY_WIRE_PAGE_MAX = 100;

/** A /v1 `created`/`updated` (unix seconds) as the ISO string the domain rows carry. */
export function isoFromUnixSeconds(seconds: number | null | undefined): string {
  if (seconds === null || seconds === undefined || !Number.isFinite(seconds)) return '';
  return new Date(seconds * 1000).toISOString();
}

export interface RegistryWireRegistry {
  id: string; slug: string; name: string; purpose: string; description: string;
  category_root: string; entry_term: string; visibility: RegistryRow['visibility'];
  submission_policy: RegistryRow['submissionPolicy']; tags?: unknown;
  services_enabled: boolean; bound_site_id: string | null;
}

export interface RegistryWireSection {
  id: string; key: string; label: string; description: string; sort_order: number;
}

export interface RegistryWireFieldDef {
  id: string; section_id: string; key: string; type: FieldDefRow['type']; label: string;
  help: string; required: boolean; sort_order: number; config: Record<string, unknown>;
  visibility: FieldDefRow['visibility']; show_if: FieldDefRow['showIf'];
}

export interface RegistryWireEntry {
  id: string; registry_id: string; slug: string; display_name: string; summary: string;
  photo_attachment_id: string | null; provider_type: EntryRow['providerType'];
  category: string; keywords: string[]; location_text: string; country_code: string;
  region_code: string; geo: EntryRow['geo']; area_served: Record<string, unknown>;
  delivery_mode: EntryRow['deliveryMode']; links: EntryLink[];
  contact_mode: EntryRow['contactMode']; languages: string[]; status: EntryRow['status'];
  visibility: EntryRow['visibility']; values: Record<string, unknown>;
  value_visibility: EntryRow['valueVisibility']; created: number;
}

export interface RegistryWireService {
  id: string; title: string; description: string; pricing_model: ServiceRow['pricingModel'];
  price_min: number | null; price_max: number | null; currency: string; unit: string;
  delivery_mode: ServiceRow['deliveryMode']; sort_order: number;
}

/**
 * `tags` joined the row on 2026-08-25, so a backend deploy older than this frontend answers
 * without it — and `RegistryDetailsPanel` hands the value straight to `TagSetField`, which
 * has an array's methods called on it. The wire type is `unknown` for that reason: the
 * required domain type is exactly the thing an `as T` would hide the absence behind.
 * Normalised once here so every consumer stays free of `?? []`.
 */
export function registryFromWire(w: RegistryWireRegistry): RegistryRow {
  return {
    id: w.id, slug: w.slug, name: w.name, purpose: w.purpose, description: w.description,
    categoryRoot: w.category_root, entryTerm: w.entry_term, visibility: w.visibility,
    submissionPolicy: w.submission_policy,
    tags: Array.isArray(w.tags) ? (w.tags as string[]) : [],
    servicesEnabled: w.services_enabled, boundSiteId: w.bound_site_id,
  };
}

export function sectionFromWire(w: RegistryWireSection): SectionRow {
  return { id: w.id, key: w.key, label: w.label, description: w.description, sortOrder: w.sort_order };
}

export function fieldDefFromWire(w: RegistryWireFieldDef): FieldDefRow {
  return {
    id: w.id, sectionId: w.section_id, key: w.key, type: w.type, label: w.label, help: w.help,
    required: w.required, sortOrder: w.sort_order, config: w.config, visibility: w.visibility,
    showIf: w.show_if,
  };
}

export function entryFromWire(w: RegistryWireEntry): EntryRow {
  return {
    id: w.id, registryId: w.registry_id, slug: w.slug, displayName: w.display_name,
    summary: w.summary, photoAttachmentId: w.photo_attachment_id, providerType: w.provider_type,
    category: w.category, keywords: w.keywords, locationText: w.location_text,
    countryCode: w.country_code, regionCode: w.region_code, geo: w.geo,
    areaServed: w.area_served, deliveryMode: w.delivery_mode, links: w.links,
    contactMode: w.contact_mode, languages: w.languages, status: w.status,
    visibility: w.visibility, values: w.values, valueVisibility: w.value_visibility,
    createdAt: isoFromUnixSeconds(w.created),
  };
}

export function serviceFromWire(w: RegistryWireService): ServiceRow {
  return {
    id: w.id, title: w.title, description: w.description, pricingModel: w.pricing_model,
    priceMin: w.price_min, priceMax: w.price_max, currency: w.currency, unit: w.unit,
    deliveryMode: w.delivery_mode, sortOrder: w.sort_order,
  };
}

interface RegistryWirePublicField {
  key: string; label: string; type: PublicEntry['fields'][number]['type'];
  value: unknown; visibility: PublicEntry['fields'][number]['visibility'];
}

interface RegistryWirePublicService {
  title: string; description: string; pricing_model: string; price_min: number | null;
  price_max: number | null; currency: string; unit: string; delivery_mode: string;
}

export interface RegistryWireProfilePage {
  registry: { slug: string; name: string; bound_site_id: string | null };
  entry: {
    slug: string; display_name: string; summary: string; photo_attachment_id: string | null;
    provider_type: string; category: string; keywords: string[]; location_text: string;
    country_code: string; region_code: string; geo: PublicEntry['geo'];
    area_served: Record<string, unknown>; delivery_mode: string;
    links: Array<{ label: string; url: string }>; contact_mode: string; languages: string[];
    fields: RegistryWirePublicField[]; services: RegistryWirePublicService[];
    image_urls: Record<string, string>;
  };
  json_ld: Record<string, unknown>;
}

/** The entry-profile body (`GET /v1/registry_entries/{slug}?registry=…`) as `EntryProfilePage`. */
export function profilePageFromWire(w: RegistryWireProfilePage): EntryProfilePage {
  const e = w.entry;
  return {
    registry: { slug: w.registry.slug, name: w.registry.name, boundSiteId: w.registry.bound_site_id },
    entry: {
      slug: e.slug, displayName: e.display_name, summary: e.summary,
      photoAttachmentId: e.photo_attachment_id, providerType: e.provider_type,
      category: e.category, keywords: e.keywords, locationText: e.location_text,
      countryCode: e.country_code, regionCode: e.region_code, geo: e.geo,
      areaServed: e.area_served, deliveryMode: e.delivery_mode, links: e.links,
      contactMode: e.contact_mode, languages: e.languages,
      fields: e.fields.map((f) => ({
        key: f.key, label: f.label, type: f.type, value: f.value, visibility: f.visibility,
      })),
      services: e.services.map((s) => ({
        title: s.title, description: s.description, pricingModel: s.pricing_model,
        priceMin: s.price_min, priceMax: s.price_max, currency: s.currency, unit: s.unit,
        deliveryMode: s.delivery_mode,
      })),
      imageUrls: e.image_urls,
    },
    jsonLd: w.json_ld,
  };
}

// --- request bodies -------------------------------------------------------------------
//
// Each table names, per resource, the domain key and its /v1 key. A key the table does not
// list (`id`, a read-only `createdAt`) is never sent; an absent key stays absent, which is
// what a PATCH-shaped update depends on. Values are passed through as they are — the nested
// maps keep their own keys on the wire.

type KeyTable = Readonly<Record<string, string>>;

function wireBody(body: object, table: KeyTable): Record<string, unknown> {
  const out: Record<string, unknown> = {};
  for (const [domainKey, value] of Object.entries(body)) {
    const wireKey = table[domainKey];
    if (wireKey !== undefined && value !== undefined) out[wireKey] = value;
  }
  return out;
}

const REGISTRY_KEYS: KeyTable = {
  slug: 'slug', name: 'name', purpose: 'purpose', description: 'description',
  categoryRoot: 'category_root', entryTerm: 'entry_term', visibility: 'visibility',
  submissionPolicy: 'submission_policy', tags: 'tags', servicesEnabled: 'services_enabled',
  boundSiteId: 'bound_site_id',
};
const SECTION_KEYS: KeyTable = {
  key: 'key', label: 'label', description: 'description', sortOrder: 'sort_order',
};
const FIELD_DEF_KEYS: KeyTable = {
  sectionId: 'section_id', key: 'key', type: 'type', label: 'label', help: 'help',
  required: 'required', sortOrder: 'sort_order', config: 'config', visibility: 'visibility',
  showIf: 'show_if',
};
const ENTRY_KEYS: KeyTable = {
  slug: 'slug', displayName: 'display_name', summary: 'summary',
  photoAttachmentId: 'photo_attachment_id', providerType: 'provider_type',
  category: 'category', keywords: 'keywords', locationText: 'location_text',
  countryCode: 'country_code', regionCode: 'region_code', geo: 'geo',
  areaServed: 'area_served', deliveryMode: 'delivery_mode', links: 'links',
  contactMode: 'contact_mode', languages: 'languages', status: 'status',
  visibility: 'visibility', values: 'values', valueVisibility: 'value_visibility',
};
const SERVICE_KEYS: KeyTable = {
  title: 'title', description: 'description', pricingModel: 'pricing_model',
  priceMin: 'price_min', priceMax: 'price_max', currency: 'currency', unit: 'unit',
  deliveryMode: 'delivery_mode', sortOrder: 'sort_order',
};

export const registryBodyToWire = (b: Partial<RegistryRow>) => wireBody(b, REGISTRY_KEYS);
export const sectionBodyToWire = (b: Partial<SectionRow>) => wireBody(b, SECTION_KEYS);
export const fieldDefBodyToWire = (b: Partial<FieldDefRow>) => wireBody(b, FIELD_DEF_KEYS);
export const entryBodyToWire = (b: EntryWrite) => wireBody(b, ENTRY_KEYS);
export const serviceBodyToWire = (b: Partial<ServiceRow>) => wireBody(b, SERVICE_KEYS);
