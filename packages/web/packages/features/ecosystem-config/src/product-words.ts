// What the Product site pane and its Custom domain section both need to word their sentences:
// how they name the product, and the host of an address.

/** The product's name in each place a sentence needs it: "Temporal", or "this product". */
export interface ProductWords {
  /** Mid-sentence: "Temporal" or "this product". */
  name: string;
  /** Sentence-initial: "Temporal" or "This product". */
  Name: string;
  /** Mid-sentence possessive: "Temporal's" or "this product's". */
  its: string;
  /** Sentence-initial possessive: "Temporal's" or "This product's". */
  Its: string;
}

/** The words for a product with this name, or for "this product" when it has none. */
export const wordsFor = (productName: string | undefined): ProductWords =>
  productName
    ? { name: productName, Name: productName, its: `${productName}'s`, Its: `${productName}'s` }
    : { name: "this product", Name: "This product", its: "this product's", Its: "This product's" };

/** The host of an origin (`temporal.example.com` for `https://temporal.example.com`), or null for none or one that does not parse. */
export const hostOf = (origin: string | null | undefined): string | null => {
  if (!origin) return null;
  try {
    return new URL(origin).host;
  } catch {
    return null;
  }
};
