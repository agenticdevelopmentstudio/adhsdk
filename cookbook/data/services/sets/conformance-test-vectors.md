
Vectors marked with a test name are asserted in `packages/web/packages/data/src/sets/__tests__/sets.test.ts`, which stubs only `authedJson`, `authedRequest` and `listAllV1`. The others follow from the source.

| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| sets-001 | set-row-mapping, list-sorted, ecosystem-query, list-personal | `list("eco 1")` with rows named Team then Pro (test: "lists the ecosystem's sets by name, camel-cased; personal sets only when asked") | `listAllV1` called with `/api/v1/sets?ecosystem=eco+1`; result names `["Pro","Team"]`; first row `{id:"s-1",slug:"pro",name:"Pro",description:"",isDefault:false,isPersonal:false,personalCustomerId:null,contains:["s-0"],values:[{kind:"limit",key:"usage.tier",value:"pro"}]}` |
| sets-002 | list-personal | `list("eco-1", {personal:true})` (same test) | `listAllV1` called with `/api/v1/sets?ecosystem=eco-1&personal=true` |
| sets-003 | set-row-defaults | `toSet` of a wire row with `description: null`, no `personal_customer_id`, no `contains`, no `values` | `description:""`, `personalCustomerId:null`, `contains:[]`, `values:[]` |
| sets-004 | create-body, create-returns | `create("eco-1", {slug:"pro",name:"Pro",isDefault:true})` (test: "creates and edits with snake_case bodies, sending only what is given") | POST `/api/v1/sets?ecosystem=eco-1`, body `{slug:"pro",name:"Pro",is_default:true}` |
| sets-005 | create-body | `create("eco-1", {slug:"me",name:"Me",personalCustomerId:"c-1"})` (same test) | body `{slug:"me",name:"Me",personal_customer_id:"c-1"}` |
| sets-006 | create-body | `create("eco-1", {slug:"a",name:"A",personalCustomerId:null,description:""})` | body `{slug:"a",name:"A",description:""}` (null customer omitted, empty description sent) |
| sets-007 | edit-body, id-encoding | `edit("eco-1","s-1",{name:"Pro plus"})` (same test) | POST `/api/v1/sets/s-1?ecosystem=eco-1`, body `{name:"Pro plus"}` |
| sets-008 | edit-default-clears | `edit("eco-1","s-1",{isDefault:true})` | body `{is_default:true}` and nothing else |
| sets-009 | remove-delete | `remove("eco-1","s-1")` (test: "deletes by id") | `authedRequest("/api/v1/sets/s-1?ecosystem=eco-1", {method:"DELETE"})`; resolves with no value |
| sets-010 | members-replace | `setMembers("eco-1","s-1",["s-0","s-3"])` (test: "replaces containment and values on their own routes") | POST `/api/v1/sets/s-1/members?ecosystem=eco-1`, body `{contains:["s-0","s-3"]}` |
| sets-011 | values-replace | `setValues("eco-1","s-1",[{kind:"permission",key:"storage",value:true},{kind:"limit",key:"storage.bytes",value:1024}])` (same test) | POST `/api/v1/sets/s-1/values?ecosystem=eco-1`, body `{values:[...]}` unchanged |
| sets-012 | id-encoding | `edit("eco-1","a/b",{name:"x"})` | URL path is `/api/v1/sets/a%2Fb` |
| sets-013 | grants-list, grant-row-mapping, grant-row-defaults | `grants("eco-1","c-1")` with an `owner_id:"c-1"` row (test: "lists a customer's grants, owner_id read as the customer") | `listAllV1` called with `/api/v1/set_grants?ecosystem=eco-1&customer=c-1`; row has `customerId:"c-1"`, `setId:"s-1"`, `source:"direct"`, `revokedAt:null` |
| sets-014 | grant-timestamps-verbatim | `toSetGrant` with `revoked_at:"2026-11-02T00:00:00.000Z"` | `revokedAt:"2026-11-02T00:00:00.000Z"` |
| sets-015 | grant-call | `grant("eco-1",{customerId:"c-1",setId:"s-2"})` with response `{grant_id:"g-2",revoked:["g-1"]}` (test: "grants, reporting what the grant revoked, and revokes by grant id") | POST `/api/v1/set_grants?ecosystem=eco-1`, body `{customer_id:"c-1",set_id:"s-2"}`; returns `{grantId:"g-2",revoked:["g-1"]}` |
| sets-016 | grant-call | `grant` with response `{grant_id:"g-3"}` | returns `{grantId:"g-3",revoked:[]}` |
| sets-017 | revoke-call | `revoke("eco-1","g-2")` (same test as sets-015) | `authedRequest` URL `/api/v1/set_grants/g-2?ecosystem=eco-1` |
| sets-018 | effective-call, answer-effective, answer-valid-until, answer-guard | `effective("eco-1","c-1")` with `{held:["s-1"],permissions:["storage"],read_only:[],limits:{"usage.tier":"pro"},valid_until:null}` (test: "reads the effective answer in each of its three forms") | URL `/api/v1/set_grants/effective/c-1?ecosystem=eco-1`; result `{held:["s-1"],permissions:["storage"],readOnly:[],limits:{"usage.tier":"pro"},validUntil:null}`; `isEffectiveSets` true |
| sets-019 | answer-absent, answer-unresolved, answer-guard | `toSetsAnswer(null)`, `toSetsAnswer(undefined)`, `toSetsAnswer({error:"unresolved"})` (same test) | `null`, `null`, `{error:"unresolved"}`; `isEffectiveSets` is false for the unresolved value and for `null` |
| sets-020 | answer-effective, answer-valid-until | `toSetsAnswer({})` | `{held:[],permissions:[],readOnly:[],limits:{}}` with no `validUntil` key |
| sets-021 | answer-unresolved | `toSetsAnswer({error:"unresolved", held:["s-1"]})` | `{error:"unresolved"}` only |
| sets-022 | offer-set-call | `setOfferSet("eco-1","o-1","s-1")` then `setOfferSet("eco-1","o-1",null)` (test: "sets or clears the set an offer sells") | POST `/api/v1/offers/o-1/set?ecosystem=eco-1`; bodies `{set_id:"s-1"}` then `{set_id:null}`; both resolve with no value |
| sets-023 | refusal-detect, refusal-fields, refusal-error-class, write-refusal-conversion | `setMembers("eco-1","s-1",["s-1"])` rejected with a 422 `AuthHttpError` whose body error is `{code:"set_refused",message:"a containment loop",rule:6}` (test: "turns a 422 set_refused into a SetRefusedError carrying the rule") | rejects with a `SetRefusedError` whose `refusal` equals `{rule:6,message:"a containment loop"}` |
| sets-024 | refusal-fields | `asSetRefusedError` of a 422 with `rule:8, limits:["usage.tier"], containers:["s-9"], customers:2` (test: "keeps the limits, containers and holder count a refusal names") | `refusal` equals `{rule:8,message:"m",limits:["usage.tier"],containers:["s-9"],customers:2}` |
| sets-025 | refusal-fields | 422 `set_refused` with a numeric `rule` and no `message` in the body | `refusal.message` equals the thrown error's own message |
| sets-026 | refusal-detect, refusal-duck-typed | `asSetRefusedError` of a 422 with `code:"invalid"`, of a 400 error, and of `new Error("network")` (test: "leaves every other error as it was") | `null` for each |
| sets-027 | refusal-detect | 422 whose body `error.code` is `"set_refused"` but whose `rule` is the string `"6"` | `null` |
| sets-028 | refusal-duck-typed | A plain object (not an `Error`) with `status:422` and a `set_refused` body | `null` |
| sets-029 | other-errors-unchanged | `create("eco-1",{slug:"a",name:"A"})` where `authedJson` rejects with a 403 `AuthHttpError` (same test as sets-026) | rejects with that same error object |
| sets-030 | entries-absent, entries-shape, entries-limits-copied | `toSetEntries({limits:[]})`; `toSetEntries(undefined)`; `toSetEntries({permission:true,limits:[{key:"storage.bytes",type:"bytes",label:"Storage"}]})` (the test "maps set_entries onto the catalog feature, and drops an empty one" asserts only the `{limits:[]}` case; the others follow from the source) | `undefined`; `undefined`; `{permission:true,limits:[{key:"storage.bytes",type:"bytes",label:"Storage"}]}` with the limit a new object |
| sets-031 | entries-shape | `toSetEntries({permission:true})` | `{permission:true}` with no `limits` key |
| sets-032 | entry-features | `setEntryFeatures` of features b (permission entry), a (none), c (a tier limit) (test: "keeps only the features that contribute, in catalog order") | keys `["b","c"]` |
| sets-033 | revoke-refusal-conversion | `revoke("eco-1","g-2")` where `authedRequest` rejects with a 422 `set_refused` | rejects with the raw 422 error, not a `SetRefusedError` (follows from the source; the backend's revoke route never sends this body) |
| sets-034 | entry-point, client-directive | Import `asSetRefusedError`, `setsApi`, `toSetsAnswer` and the type `SetRow` from the package entry `@adh-sdk/data/sets` | All resolve; the tests import the values (not the type) from `..` (the `index.ts`) |
| sets-035 | no-transport-policy | `list("eco-1")` where `listAllV1` rejects with a network error | `list` rejects with that error; no retry is made and `listAllV1` is called once |
| sets-036 | refusal-rule-meaning | `asSetRefusedError` of a 422 `set_refused` with `rule:9` | `refusal.rule` equals 9; a rule number outside the union (for example 5) is accepted and passed through unchecked |

