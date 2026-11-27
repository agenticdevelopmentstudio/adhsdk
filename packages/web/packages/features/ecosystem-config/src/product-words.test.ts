// The one `wordsFor` the Product site pane and its Custom domain section share.
import { describe, expect, it } from "vitest";

import { wordsFor } from "./product-words";

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
