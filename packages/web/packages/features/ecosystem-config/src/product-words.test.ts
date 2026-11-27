// The one `wordsFor` the Product site pane and its Custom domain section share.
import { describe, expect, it } from "vitest";

import { hostOf, wordsFor } from "./product-words";

describe("hostOf", () => {
  it("gives the host of an origin, port included", () => {
    expect(hostOf("https://temporal.example.com")).toBe("temporal.example.com");
    expect(hostOf("http://localhost:3000")).toBe("localhost:3000");
  });

  it("is null for no origin and for one that does not parse", () => {
    expect(hostOf(null)).toBeNull();
    expect(hostOf(undefined)).toBeNull();
    expect(hostOf("")).toBeNull();
    expect(hostOf("not a url")).toBeNull();
  });
});

describe("wordsFor", () => {
  it("names the product in every form a sentence needs", () => {
    expect(wordsFor("Temporal")).toEqual({ name: "Temporal", Name: "Temporal", its: "Temporal's", Its: "Temporal's" });
  });

  it("says this product without a name, capitalised at the start of a sentence", () => {
    expect(wordsFor(undefined)).toEqual({
      name: "this product",
      Name: "This product",
      its: "this product's",
      Its: "This product's",
    });
  });
});
