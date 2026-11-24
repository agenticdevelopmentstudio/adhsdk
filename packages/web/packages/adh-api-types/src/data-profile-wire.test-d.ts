// The drift gate for `@adh-sdk/data`'s profile wire shapes — the thing that package's
// header could not do on its own. It transcribes the backend's rows by hand and CITES its
// sources in a comment, and a citation is not a check: a backend column rename regenerates
// ./schema.ts, every consumer still compiles against the hand-written interface, and the field
// simply reads `undefined` in the Profile editor and the public UserCard. Nothing errors, on
// any site.
//
// IT LIVES HERE, NOT THERE, and that is the whole reason this file moved. `data` is a PORTABLE
// package, and `tools/check_boundaries.py` (adh runs it as verify_toolkit_boundary.py) refuses
// any import of the adh vocabulary tier from one — the direction is one-way by design, because
// such an import resolves fine inside adh's workspace and fails only in a consumer. A gate is
// not a reason to open a hole in that: this package IS the adh tier, it already devDepends on
// portable siblings (`crud`, `api-explorer`), and measuring a transcription needs both sides
// regardless of which one holds the file. So the dependency points the sanctioned way and the
// guard needs no exemption.
//
// Consequence worth knowing: `moduleResolution: "bundler"` with no `customConditions` takes
// `data`'s `types` condition, so the shapes below are read from its BUILT `dist/*.d.ts`, not
// from `src/`. That is fail-closed rather than silent — an unbuilt `data` makes this file fail
// to resolve — and it does not weaken what the gate is for: a backend rename regenerates
// ./schema.ts, which is read straight from source here, so it reddens on the same run.
//
// Run by `tsc --noEmit` (`pnpm lint` / `pnpm test`), not by vitest: `.test-d.ts` is outside
// vitest's include glob, exactly as ./index.test-d.ts is. Every entry in `Checks` must be
// literally `true`, or `Expect<… extends true>` fails and the package stops type-checking.
import type { RequestBody, SuccessBody } from "./index";
import type {
  SocialLinkWire,
  SocialLinkWriteWire,
  SocialLink,
  SocialLinkWrite,
  AddressWire,
  AddressWriteWire,
  Address,
  AddressWrite,
  PrivacyGrantWire,
  PrivacyGrant,
  PrivacyTargetTable,
  UsageRowWire,
  UsageRow,
} from "@adh-sdk/data/profile";

// ── assertion utilities (same set as ./index.test-d.ts) ──────────────────────────────────
type Expect<T extends true> = T;
type Equal<A, B> =
  (<T>() => T extends A ? 1 : 2) extends <T>() => T extends B ? 1 : 2 ? true : false;
type Extends<A, B> = A extends B ? true : false;
type IsNever<T> = [T] extends [never] ? true : false;
type IsAny<T> = 0 extends 1 & T ? true : false;

/** Keys the client would SEND that the backend does not accept — the write-side rename check.
 *  Plain assignability cannot see these: excess-property checking applies to fresh object
 *  literals, not to one declared type measured against another. */
type UnknownKeys<Written, Wire> = Exclude<keyof Written, keyof Wire>;

/** A type with intersections flattened, so two structurally identical shapes compare `Equal`. */
type Flat<T> = { [K in keyof T]: T[K] };
/** The generated list row carries a per-resource `object` discriminator the wire types omit. */
type NoObject<T> = Flat<Omit<T, "object">>;

// ── what the backend actually declares ───────────────────────────────────────────────────
// `/v1` collections answer `{object: 'list', data: [...]}`, so a row is `["data"][number]`.
type WireSocialLink = SuccessBody<"/v1/content/social_links", "get">["data"][number];
type WireAddress = SuccessBody<"/v1/content/addresses", "get">["data"][number];
// There is no standalone privacy route in /v1: the grants are the `privacy` include of
// `GET /v1/account` (optional there, since it only appears when asked for) and are written by
// the `privacy` member of the `POST /v1/account` body.
type WirePrivacyGrant = NonNullable<
  SuccessBody<"/v1/account", "get">["privacy"]
>["items"][number];
type WirePrivacyWrite = NonNullable<RequestBody<"/v1/account", "post">["privacy"]>;
type WirePrivacyEcho = NonNullable<SuccessBody<"/v1/account", "post">["privacy"]>;
type WireUsageRow = SuccessBody<"/v1/usage/summary", "get">["data"][number];
type WireSocialLinkCreate = RequestBody<"/v1/content/social_links", "post">;
type WireAddressCreate = RequestBody<"/v1/content/addresses", "post">;

// Exported so every assertion is referenced and none can be dead-stripped.
export type Checks = [
  // ── FAIL TO CHECK ───────────────────────────────────────────────────────────────────
  // A mistyped path resolves to `never`, and `never extends anything` is TRUE — so every
  // assertion below would pass while measuring nothing. `any` swallows them the same way.
  // Both are refused first, for the same reason the Python guards in adh-tools' sites/scripts refuse
  // an empty scan.
  Expect<Equal<IsNever<WireSocialLink>, false>>,
  Expect<Equal<IsNever<WireAddress>, false>>,
  Expect<Equal<IsNever<WirePrivacyGrant>, false>>,
  Expect<Equal<IsNever<WirePrivacyWrite>, false>>,
  Expect<Equal<IsNever<WirePrivacyEcho>, false>>,
  Expect<Equal<IsNever<WireUsageRow>, false>>,
  Expect<Equal<IsNever<WireSocialLinkCreate>, false>>,
  Expect<Equal<IsNever<WireAddressCreate>, false>>,
  Expect<Equal<IsAny<WireSocialLink>, false>>,
  Expect<Equal<IsAny<WirePrivacyGrant>, false>>,
  Expect<Equal<IsAny<WireUsageRow>, false>>,

  // ── READ SIDE ───────────────────────────────────────────────────────────────────────
  // Everything the backend sends must satisfy the transcription: a renamed, removed or
  // retyped column stops the generated row from being assignable, and this goes red.
  //
  // The direction is deliberate. The reverse — requiring the transcription to name every
  // column — would fail on a purely ADDITIVE backend change, which is not a client defect:
  // this file is a narrowing VIEW of the row, and a field it does not read cannot come out
  // `undefined` anywhere.
  Expect<Extends<WireSocialLink, SocialLinkWire>>,
  Expect<Extends<WireAddress, AddressWire>>,
  Expect<Extends<WirePrivacyGrant, PrivacyGrantWire>>,
  Expect<Extends<WirePrivacyEcho, PrivacyGrantWire>>,
  Expect<Extends<WireUsageRow, UsageRowWire>>,

  // `UsageRowWire` is the whole projection rather than a view of a row, so it is pinned EXACTLY:
  // a new field on the usage summary is a field the usage page is meant to show. (The generated
  // row also carries its `object` discriminator, which the transcription leaves out.)
  Expect<Equal<NoObject<WireUsageRow>, NoObject<UsageRowWire>>>,

  // ── THE ONE DELIBERATE DIVERGENCE ───────────────────────────────────────────────────
  // `PrivacyTargetTable` widens the generated enum to `string` on purpose (see `data`'s
  // src/profile/wire.ts:
  // a client that hard-coded the members would refuse a target the backend later adds). That
  // is why the read-side check above runs one way only, and pinning the asymmetry here keeps
  // it a stated decision — if someone narrows the alias back to the union, this entry flips
  // and says so, instead of the widening quietly disappearing.
  Expect<Equal<PrivacyTargetTable, string>>,
  Expect<Equal<Extends<PrivacyGrantWire, WirePrivacyGrant>, false>>,

  // ── WRITE SIDE ──────────────────────────────────────────────────────────────────────
  // Every field the editor sends must still be a column the backend accepts. A rename shows
  // up as a leftover key here — a create that silently drops the value otherwise. The wire
  // bodies are what actually go out; the camelCase app writes are mapped onto them by
  // profile.ts, so both are measured.
  Expect<Equal<UnknownKeys<SocialLinkWriteWire, WireSocialLinkCreate>, never>>,
  Expect<Equal<UnknownKeys<AddressWriteWire, WireAddressCreate>, never>>,
  Expect<Extends<SocialLinkWriteWire, WireSocialLinkCreate>>,
  Expect<Extends<AddressWriteWire, WireAddressCreate>>,
  // The privacy write is `{target_table, target_id, audience_mask}` — all three required.
  Expect<Equal<UnknownKeys<PrivacyGrantWire, WirePrivacyWrite>, never>>,
  Expect<Extends<{ target_table: "avatar"; target_id: string; audience_mask: number }, WirePrivacyWrite>>,
  // The app write shapes still name only fields that exist on the wire body once snake-cased.
  Expect<Equal<Exclude<keyof SocialLinkWrite, "sortOrder" | keyof SocialLinkWriteWire>, never>>,
  Expect<Equal<Exclude<keyof AddressWrite, "postalCode" | keyof AddressWriteWire>, never>>,
];

// The write shapes are a SUBSET on purpose — the server owns identity, tenancy, ownership and
// the sync stamps, so the editor must not be able to name them. `@ts-expect-error` is itself a
// tsc error when the line compiles, so each of these fails the build if a server-managed column
// ever becomes writable from here without the decision being made explicitly.
export const guardedColumns = (): void => {
  // @ts-expect-error — `id` is server-managed; a client must not send one.
  const badLink: SocialLinkWrite = { platform: "x", url: "u", handle: "h", id: "s1" };
  const badAddress: AddressWrite = {
    label: "Home",
    line1: "1",
    line2: "",
    city: "c",
    region: "r",
    postalCode: "p",
    country: "US",
    // A directive suppresses only the line DIRECTLY below it, and an excess property in a
    // multi-line literal is reported at the property — so this one sits here, not above the
    // `const`, where it would report as unused and prove nothing.
    // @ts-expect-error — `ownerId` is decided by the `?workspace=` scope, never by the body.
    ownerId: "o1",
  };
  void badLink;
  void badAddress;
};
