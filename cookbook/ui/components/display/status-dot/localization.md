
StatusDot renders no strings of its own — the only text-bearing surface is the
consumer-supplied `label`, exposed verbatim as `aria-label`
(**passes-label-through-verbatim**). The consumer MUST supply `label` already
localized; the component MUST NOT concatenate, translate, or otherwise
transform it before setting `aria-label`.

