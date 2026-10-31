import { afterEach, describe, expect, it } from "vitest";
import { cleanup, render } from "@testing-library/react";
import { DetailsPage } from "../details/DetailsPage";

afterEach(cleanup);

describe("DetailsPage", () => {
  // The page renders inside an app shell that has the page's <main>, so a second one here
  // would leave a reader with two.
  it("is an article, not a main", () => {
    const { container } = render(<DetailsPage siteId="billing" />);
    expect(container.querySelector("main")).toBeNull();
    expect(container.querySelector("article h1")).not.toBeNull();
  });

  it("opens with the lead as its first paragraph, not the rail label", () => {
    const { container } = render(<DetailsPage siteId="billing" />);
    expect(container.querySelector("p")?.className).toBe("adh-details__lead");
  });
});
