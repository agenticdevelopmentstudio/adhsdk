// Type-level verification of the contract helpers — validated by `tsc --noEmit`
// (`pnpm test`). Every entry in `Checks` must be exactly `true` (via Expect<…>),
// and each `@ts-expect-error` line fails to compile if the error it expects does
// NOT occur (an unused @ts-expect-error is itself a tsc error). So a regression in
// a guard — RequestBody resolving to `never`/`any`, a server-managed column
// leaking into a create body, a wrong nullability — turns this file red. This is
// how the type guards are proven to catch what they claim to.
import type { RequestBody, SuccessBody } from './index'

// ── assertion utilities ──────────────────────────────────────────────────────
type Expect<T extends true> = T
type Equal<A, B> =
  (<T>() => T extends A ? 1 : 2) extends (<T>() => T extends B ? 1 : 2) ? true : false
type Extends<A, B> = A extends B ? true : false
type HasKey<T, K extends PropertyKey> = K extends keyof T ? true : false
type IsNever<T> = [T] extends [never] ? true : false
type IsAny<T> = 0 extends 1 & T ? true : false

// A /v1 list answers the Stripe-style envelope; its rows are snake_case.
type CustomerList = SuccessBody<'/v1/customers', 'get'>
type Customer = CustomerList['data'][number]
// Customer create body — exercises the server-managed-column stripping
// (id/created/updated absent from the body).
type CustomerCreate = RequestBody<'/v1/customers', 'post'>
// Update is POST on the item path; every writable column is optional.
type CustomerUpdate = RequestBody<'/v1/customers/{id}', 'post'>

// Exported so the assertions are referenced (never dead-stripped); any `false`
// element fails its `Expect<… extends true>` and breaks the build.
export type Checks = [
  // ── SuccessBody (response side) ──
  Expect<Equal<CustomerList['object'], 'list'>>, //           the list envelope
  Expect<Equal<CustomerList['has_more'], boolean>>,
  Expect<Extends<CustomerList['data'], unknown[]>>,
  Expect<Equal<Customer['id'], string>>,
  // nullability is preserved (the property that caught the admin email/userEmail bug):
  Expect<Equal<Customer['email'], string | null>>,
  Expect<Equal<Customer['display_name'], string | null>>,
  Expect<Equal<Customer['created'], number>>, //              unix seconds, not ISO
  Expect<Equal<HasKey<Customer, 'createdAt'>, false>>, //     no legacy camelCase key
  Expect<HasKey<SuccessBody<'/v1/customers', 'post', 201>, 'id'>>, // status-keyed
  Expect<Equal<IsNever<CustomerList>, false>>,
  Expect<Equal<IsAny<CustomerList>, false>>,

  // ── RequestBody (request side) ──
  Expect<HasKey<CustomerCreate, 'email'>>, //               writable columns present
  Expect<HasKey<CustomerCreate, 'display_name'>>,
  Expect<Equal<HasKey<CustomerCreate, 'id'>, false>>, //    server-managed columns stripped
  Expect<Equal<HasKey<CustomerCreate, 'created'>, false>>,
  Expect<Equal<HasKey<CustomerCreate, 'updated'>, false>>,
  Expect<Equal<IsNever<CustomerCreate>, false>>,
  Expect<Equal<IsAny<CustomerCreate>, false>>,
  Expect<Equal<IsNever<CustomerUpdate>, false>>,
]

// a valid create payload compiles:
const okCustomer: CustomerCreate = { email: 'test@example.com', slug: 'test' }
void okCustomer

// @ts-expect-error — `bogus` is not a writable column; the guard must reject it.
const badCustomer: CustomerCreate = { email: 'x@x.com', slug: 'x', bogus: 1 }
void badCustomer

// @ts-expect-error — the legacy camelCase name is not a /v1 column.
const camelCustomer: CustomerCreate = { slug: 'x', displayName: 'X' }
void camelCustomer

// an update (POST on the item path) accepts a subset of the writable columns:
const patch: CustomerUpdate = { email: 'new@example.com' }
void patch
