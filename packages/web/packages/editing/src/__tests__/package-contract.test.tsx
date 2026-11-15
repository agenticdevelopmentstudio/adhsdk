/// <reference types="vite/client" />
import "@testing-library/jest-dom/vitest"
import * as React from "react"
import { cleanup, fireEvent, render, screen } from "@testing-library/react"
import { afterEach, describe, expect, it, vi } from "vitest"

import { EditingContainer } from "../container"
import { text } from "../descriptors"
import { EditingHostProvider } from "../host"
import * as mainEntry from "../index"
import * as serverEntry from "../server"
import { section } from "../sections"
import type { AnySection } from "../sections"
import { teamFields, teamSections, testHost } from "./fixtures"
import type { Team } from "./fixtures"

// Sources and the manifest are read as raw text through Vite, keyed by their path from src/.
const RAW = import.meta.glob<string>(["../*.ts", "../*.tsx"], {
  query: "?raw",
  import: "default",
  eager: true,
})
const MANIFEST: string = Object.values(
  import.meta.glob<string>("../../package.json", { query: "?raw", import: "default", eager: true }),
)[0]!
const RAW_NAMES = new Set(Object.keys(RAW).map((k) => k.slice(3)))
const sourceOf = (name: string): string => {
  const hit = RAW[`../${name}`]
  if (hit === undefined) throw new Error(`no source named ${name}`)
  return hit
}
const CLEAN: Team = { displayName: "Participants", identifier: "adh.participants", archived: false }

afterEach(cleanup)

function renderPane(onCancel?: () => void): void {
  render(
    <EditingHostProvider host={testHost}>
      <EditingContainer
        record={CLEAN}
        fields={teamFields}
        sections={teamSections}
        context={{ orgSlug: "adh" }}
        onSave={vi.fn()}
        onCancel={onCancel}
      />
    </EditingHostProvider>,
  )
}

function edit(): void {
  const input = document.querySelector<HTMLElement>('[data-editing-field="displayName"]')!
  fireEvent.change(input, { target: { value: "Renamed" } })
}

const cancelButton = (): HTMLElement => screen.getByRole("button", { name: /Cancel/ })

describe("cancel availability", () => {
  it("content-editing-060 a clean pane enables Cancel only when onCancel is supplied; a dirty one always does", () => {
    renderPane(vi.fn())
    expect(cancelButton()).toBeEnabled()
    cleanup()

    renderPane(undefined)
    expect(cancelButton()).toBeDisabled()
    edit()
    expect(cancelButton()).toBeEnabled()
  })
})

describe("descriptors", () => {
  it("content-editing-061 text({ label }) defaults required and disabled to false", () => {
    const descriptor = text({ label: "Name" })
    expect(descriptor.required).toBe(false)
    expect(descriptor.disabled).toBe(false)
  })

  it("content-editing-062 the control kinds are exactly text, textarea, rdid, checkbox, select (no numeric kind)", async () => {
    const { checkbox, rdid, select, text: t, textarea } = await import("../descriptors")
    const kinds = [
      t({ label: "a" }).kind,
      textarea({ label: "b" }).kind,
      rdid({ label: "c" }).kind,
      checkbox({ label: "d" }).kind,
      select({ label: "e", options: [{ value: "x", label: "X" }] }).kind,
    ]
    expect(kinds).toEqual(["text", "textarea", "rdid", "checkbox", "select"])
    // ControlKind is a type, so the closed union is read from its declaration.
    const declaration = sourceOf("descriptors.ts")
    const union = /export type ControlKind =([^\n]+)/.exec(declaration)![1]!
    const members = [...union.matchAll(/"(\w+)"/g)].map((m) => m[1])
    expect(members).toEqual(["text", "textarea", "rdid", "checkbox", "select"])
    expect(members).not.toContain("number")
  })
})

describe("package entry points", () => {
  it("content-editing-063 the server entry runs without React and no module behind it is a client module", () => {
    // The builders run as plain functions, with no React render anywhere.
    expect(text({ label: "x" }).kind).toBe("text")
    expect(serverEntry.section("T", ["a"]).title).toBe("T")
    expect(serverEntry.dangerZone(["a"]).keys).toEqual(["a"])

    // Every module the server entry reaches is free of "use client" and of a runtime
    // React import (a type-only import is erased).
    const seen = new Set<string>()
    const walk = (name: string): void => {
      if (seen.has(name)) return
      seen.add(name)
      const code = sourceOf(name)
      expect(code, name).not.toMatch(/^\s*["']use client["']/m)
      expect(code, name).not.toMatch(/^import\s+(?!type\b)[^;\n]*from\s+["']react(-dom)?["']/m)
      for (const m of code.matchAll(/^(?:import|export)\s+(?!type\b)[^;]*?from\s+["']\.\/([^"']+)["']/gm)) {
        walk(RAW_NAMES.has(`${m[1]}.ts`) ? `${m[1]}.ts` : `${m[1]}.tsx`)
      }
    }
    walk("server.ts")
    expect(seen.size).toBeGreaterThan(1)
    expect(seen.has("container.tsx")).toBe(false)
  })

  it("content-editing-064 neither entry point exports BoundField and no export key reaches controls", () => {
    expect("BoundField" in mainEntry).toBe(false)
    expect("BoundField" in serverEntry).toBe(false)
    const pkg = JSON.parse(MANIFEST) as {
      exports: Record<string, unknown>
    }
    expect(Object.keys(pkg.exports).sort()).toEqual([".", "./server"])
  })
})

describe("layout fault logging", () => {
  it("content-editing-072 a layout fault is logged once with the package prefix, not again on re-render", () => {
    const spy = vi.spyOn(console, "error").mockImplementation(() => {})
    try {
      const faulty: readonly AnySection[] = [section("Team", ["displayName", "identifier"])]
      const tree = (): React.ReactElement => (
        <EditingHostProvider host={testHost}>
          <EditingContainer
            record={CLEAN}
            fields={teamFields}
            sections={faulty as never}
            context={{ orgSlug: "adh" }}
            onSave={vi.fn()}
          />
        </EditingHostProvider>
      )
      const { rerender } = render(tree())
      const mine = (): unknown[][] =>
        spy.mock.calls.filter((c) => typeof c[0] === "string" && c[0].startsWith("[@adh-sdk/editing]"))
      expect(screen.getAllByRole("alert").length).toBeGreaterThan(0)
      expect(mine()).toHaveLength(1)
      expect(mine()[0]![0]).toContain("archived")
      rerender(tree())
      expect(mine()).toHaveLength(1)
    } finally {
      spy.mockRestore()
    }
  })
})
