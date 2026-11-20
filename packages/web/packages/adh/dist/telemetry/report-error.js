'use client'

"use client";

// src/telemetry/report-error.ts
var reporter = null;
function setErrorReporter(next) {
  reporter = next;
}
function captureException(error, context) {
  try {
    reporter?.(error, context);
  } catch {
  }
}
function reportUnexpectedError(error, context) {
  const status = error?.status;
  if (typeof status === "number" && status < 500) return;
  captureException(error, context);
}
function reportUnlessUnauthorized(error, context) {
  const status = error?.status;
  if (status === 401) return;
  captureException(error, context);
}
export {
  captureException,
  reportUnexpectedError,
  reportUnlessUnauthorized,
  setErrorReporter
};
//# sourceMappingURL=report-error.js.map