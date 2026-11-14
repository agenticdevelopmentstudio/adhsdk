
ResizableSplit collects no personal data. `localStorage` persistence of the ratio is scoped to the browser origin (not the page) and never transmitted; consumers using `storageKey` SHOULD namespace it (e.g. prefix with a route or feature name) to avoid collisions with other components writing to the same origin's `localStorage`.

