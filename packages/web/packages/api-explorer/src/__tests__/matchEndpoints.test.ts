import { describe, it, expect } from "vitest"

import { matchEndpoints } from "../lib/getEndpoint"

const keys = (matches: Parameters<typeof matchEndpoints>[0]) => matchEndpoints(matches).map((m) => m.key)

describe("matchEndpoints", () => {
  it("matches a route whatever its placeholders are called", () => {
    expect(keys([{ method: "get", path: "/ecosystem/client-auth/{ecosystem id}" }])).toEqual([
      "GET /ecosystem/client-auth/{id}",
    ])
  })

  it("takes a route with no method as every method on its path, in method order", () => {
    expect(keys([{ path: "/auth/me" }])).toEqual(["GET /auth/me", "PATCH /auth/me"])
  })

  it("keeps the order the page names them in, each once", () => {
    expect(
      keys([
        { method: "PUT", path: "/ecosystem/applications/{app id}/client-auth" },
        { method: "GET", path: "/auth/me" },
        { path: "/auth/me" },
      ]),
    ).toEqual(["PUT /ecosystem/applications/{appId}/client-auth", "GET /auth/me", "PATCH /auth/me"])
  })

  it("leaves out a route the spec does not have", () => {
    expect(keys([{ method: "GET", path: "/no/such/route" }])).toEqual([])
  })
})
