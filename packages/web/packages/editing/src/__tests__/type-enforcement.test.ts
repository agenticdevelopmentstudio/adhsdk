import { beforeAll, describe, expect, it } from "vitest"
import ts from "typescript"

// type-enforcement.tsx holds the negative type tests: each misuse sits under a
// `@ts-expect-error`. A directive that suppresses nothing is reported by tsc as
// TS2578 ("Unused '@ts-expect-error' directive"), so a misuse that starts compiling
// shows up as exactly that diagnostic inside its own function. This file runs the real
// compiler over the package and asserts, per vector, that the function carries its
// directive and that no diagnostic (an unused directive included) lands inside it.

// Vitest runs from the package directory (its config lives there), so the cwd is the package.
const PKG = ts.sys.getCurrentDirectory()
const FILE = `${PKG}/src/__tests__/type-enforcement.tsx`

let source: ts.SourceFile
let diagnostics: readonly ts.Diagnostic[]

beforeAll(() => {
  const configPath = `${PKG}/tsconfig.json`
  const read = ts.readConfigFile(configPath, ts.sys.readFile)
  const parsed = ts.parseJsonConfigFileContent(read.config, ts.sys, PKG)
  const program = ts.createProgram({
    rootNames: [FILE],
    options: { ...parsed.options, noEmit: true },
  })
  source = program.getSourceFile(FILE)!
  diagnostics = ts.getPreEmitDiagnostics(program, source)
}, 120_000)

function rangeOf(fn: string): { start: number; end: number } {
  let found: ts.FunctionDeclaration | undefined
  ts.forEachChild(source, (node) => {
    if (ts.isFunctionDeclaration(node) && node.name?.text === fn) found = node
  })
  if (!found) throw new Error(`type-enforcement.tsx has no function ${fn}`)
  return { start: found.getFullStart(), end: found.getEnd() }
}

function messagesInside(fn: string): string[] {
  const { start, end } = rangeOf(fn)
  return diagnostics
    .filter((d) => d.file === source && d.start! >= start && d.start! < end)
    .map((d) => ts.flattenDiagnosticMessageText(d.messageText, "\n"))
}

function expectsCompileFailure(fn: string): void {
  const { start, end } = rangeOf(fn)
  // The misuse is really there, under a directive that claims it errors ...
  expect(source.text.slice(start, end)).toContain("@ts-expect-error")
  // ... and the compiler agrees: the directive is used, so nothing inside is left reporting.
  expect(messagesInside(fn)).toEqual([])
}

const CASES: ReadonlyArray<readonly [string, string]> = [
  ["content-editing-001", "misspelledFieldName"],
  ["content-editing-002", "wrongControlForTheValueType"],
  ["content-editing-003", "textControlOnABooleanField"],
  ["content-editing-004", "selectOfferingAValueTheFieldCannotHold"],
  ["content-editing-005", "selectMissingOneOfTheFieldsValues"],
  ["content-editing-006", "validateWithoutRepair"],
  ["content-editing-007", "contextNeededButNotSupplied"],
  ["content-editing-008", "contextOfTheWrongShape"],
  ["content-editing-009", "aFieldNoSectionLaysOut"],
  ["content-editing-010", "aSectionNamingAFieldThatDoesNotExist"],
  ["content-editing-011", "aDangerZoneThatForgetsAField"],
  ["content-editing-012", "onSaveExpectingADifferentRecord"],
]

describe("type enforcement (compiled by the real TypeScript compiler)", () => {
  for (const [id, fn] of CASES) {
    it(`${id} ${fn} fails to compile`, () => {
      expectsCompileFailure(fn)
    })
  }

  it("the correctly declared panes in the same file compile with no diagnostics", () => {
    for (const fn of [
      "aCorrectlyDeclaredPane",
      "aPaneWithNoRulesAndNoContext",
      "aHandlerThatReadsPartOfTheRecord",
      "aPaneEditingPartOfARecord",
    ]) {
      expect(messagesInside(fn)).toEqual([])
    }
  })
})
