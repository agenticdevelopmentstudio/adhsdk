import { describe, it, expect } from "vitest"

import { matchEndpoints } from "../lib/getEndpoint"

const keys = (matches: Parameters<typeof matchEndpoints>[0]) => matchEndpoints(matches).map((m) => m.key)

describe("matchEndpoints", () => {
  it("matches a route whatever its placeholders are called", () => {
    expect(keys([{ method: "get", path: "/v1/personas/{persona id}" }])).toEqual([
      "GET /v1/personas/{id}",
    ])
  })

  it("takes a route with no method as every method on its path, in method order", () => {
    expect(keys([{ path: "/v1/account" }])).toEqual(["GET /v1/account", "POST /v1/account"])
  })

  it("keeps the order the page names them in, each once", () => {
    expect(
      keys([
        { method: "DELETE", path: "/v1/personas/{persona id}" },
        { method: "GET", path: "/v1/account" },
        { path: "/v1/account" },
      ]),
    ).toEqual(["DELETE /v1/personas/{id}", "GET /v1/account", "POST /v1/account"])
  })

  it("leaves out a route the spec does not have", () => {
    expect(keys([{ method: "GET", path: "/no/such/route" }])).toEqual([])
  })
})
