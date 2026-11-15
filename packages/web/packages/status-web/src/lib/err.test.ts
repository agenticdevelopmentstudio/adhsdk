import { describe, it, expect } from "vitest";
import * as mod from "./err";
import { msg } from "./err";

describe("err", () => {
  it("err-001 Error returns its message", () => {
    expect(msg(new Error("boom"))).toBe("boom");
  });
  it("err-002 Error subtype omits the name prefix", () => {
    expect(msg(new TypeError("bad arg"))).toBe("bad arg");
  });
  it("err-003 empty message gives empty string", () => {
    expect(msg(new Error(""))).toBe("");
  });
  it("err-004 string is returned as is", () => {
    expect(msg("network down")).toBe("network down");
  });
  it("err-005 null", () => {
    expect(msg(null)).toBe("null");
  });
  it("err-006 undefined", () => {
    expect(msg(undefined)).toBe("undefined");
  });
  it("err-007 number", () => {
    expect(msg(42)).toBe("42");
  });
  it("err-008 plain object with message is not unwrapped", () => {
    expect(msg({ message: "x" })).toBe("[object Object]");
  });
  it("err-009 object with custom toString", () => {
    expect(msg({ toString: () => "custom" })).toBe("custom");
  });
  it("err-010 pure: same result, error unchanged", () => {
    const e = new Error("same");
    const before = { message: e.message, name: e.name, stack: e.stack };
    expect(msg(e)).toBe(msg(e));
    expect({ message: e.message, name: e.name, stack: e.stack }).toEqual(before);
  });
  it("err-011 no trimming", () => {
    expect(msg(new Error("  padded  "))).toBe("  padded  ");
  });
  it("err-012 module exports a single operation", () => {
    expect(Object.keys(mod)).toEqual(["msg"]);
    expect(typeof mod.msg).toBe("function");
  });
});
