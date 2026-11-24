
- Role: The component itself does not have a role; it contains a `<form>` element which is implicitly a form.
- Labels: All form inputs (name, email) MUST have associated `<label>` elements; labels MUST NOT use placeholders in place of labels.
- Email validation: aria-invalid MUST be set to true when a validation error exists; aria-describedby MUST reference the error message.
- Error announcement: Error messages MUST have role="alert" so screen readers announce them when they appear. The alert element is only mounted once an error occurs — it is not present in the DOM beforehand — so some browser/screen-reader combinations may not announce it as reliably as a region that exists from the start.
- Success announcement: The success message MUST have role="status" and programmatic focus (via `tabIndex={-1}` on the container) to ensure announcement — see **focus-success-message**.
- Submit button state: aria-busy="true" MUST be set when submitting to indicate to screen readers the button is working.
- Honeypot: The honeypot input MUST be hidden from both visual and assistive tech via aria-hidden="true" and removed from tab order via tabIndex={-1}.
- Touch target: The input and button heights follow from the component's Tailwind padding (`py-2` plus `text-sm` line-height), which comes to roughly 36px — below the 44px WCAG 2.5.5 target size. See Compliance (`touch-target-size`, marked `failed`).
- Autofill: The honeypot field MUST opt out of password manager autofill using the exact per-vendor attributes `autoComplete="off"`, `data-form-type="other"`, `data-1p-ignore="true"`, `data-lpignore="true"`, `data-bwignore="true"`, and `data-protonpass-ignore="true"`.

