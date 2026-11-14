
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| rich-content-001 | render-items-in-order | items = [{type: 'link', label: 'First', url: 'https://example.com'}, {type: 'link', label: 'Second', url: 'https://example.com'}] | Links render in order: "First" then "Second" |
| rich-content-002 | link-protocol-allowlist | items = [{type: 'link', label: 'Click', url: 'javascript:alert(1)'}] | No href is set; link renders as inert text "Click" |
| rich-content-003 | link-protocol-allowlist | items = [{type: 'link', label: 'Click', url: 'data:text/html,<script>alert(1)</script>'}] | No href is set; link renders as inert text "Click" |
| rich-content-004 | link-protocol-allowlist | items = [{type: 'link', label: 'Email', url: 'mailto:user@example.com'}] | Link has href="mailto:user@example.com"; user can click to open mail client |
| rich-content-005 | link-protocol-allowlist | items = [{type: 'link', label: 'Phone', url: 'tel:+1-555-1234'}] | Link has href="tel:+1-555-1234"; user can click to initiate call |
| rich-content-006 | malformed-url-handling | items = [{type: 'link', label: 'Bad', url: 'http://[bad'}] | Resolving the URL throws; no href is set; link renders as inert text "Bad" |
| rich-content-007 | safe-link-text | items = [{type: 'link', label: 'Visit Site', url: 'https://example.com'}] | Link text displays as "Visit Site" |
| rich-content-008 | safe-link-text | items = [{type: 'link', url: 'https://example.com'}] | Link text displays as "https://example.com" |
| rich-content-009 | open-links-in-new-context | items = [{type: 'link', label: 'Link', url: 'https://example.com'}] | Link has target="_blank" with rel="noopener noreferrer" (web); native platforms open in the system browser/handler, never in-app |
| rich-content-010 | hide-until-loaded | items = [{type: 'image', src: 'https://example.com/image.png', alt: 'Photo'}] | Image element is created with `display: none` (no space reserved) until the load event fires |
| rich-content-011 | hide-until-loaded | items = [{type: 'image', src: 'https://example.com/image.png'}] | Image is shown (hidden style removed) once the load event fires |
| rich-content-012 | image-error-handling | items = [{type: 'image', src: 'https://broken-url.com/image.png'}] | Hidden style is removed when the error event fires (fail-open, same as success); the browser's default broken-image indicator becomes visible in the space it now occupies |
| rich-content-013 | image-alt-text | items = [{type: 'image', src: 'https://example.com/photo.png', alt: 'Portrait'}] | Image has alt="Portrait" |
| rich-content-014 | image-alt-text | items = [{type: 'image', src: 'https://example.com/photo.png'}] | Image has alt="" (empty string, decorative) |
| rich-content-015 | unknown-item-skip | items = [{type: 'link', label: 'Link', url: 'https://example.com'}, {type: 'unknown'}, {type: 'link', label: 'Link2', url: 'https://example.com'}] | Two links render; unknown item is skipped silently |
| rich-content-016 | link-protocol-allowlist | items = [{type: 'link', label: 'Rel', url: '/page'}] | URL has no scheme, so resolving it against the internal base yields `https:` regardless of the page's own scheme; href is set to "/page" and the link is clickable |
| rich-content-017 | link-protocol-allowlist | items = [{type: 'link', label: 'Click', url: 'vbscript:msgbox(1)'}] | No href is set; link renders as inert text "Click" |
| rich-content-018 | link-protocol-allowlist | items = [{type: 'link', label: 'Click', url: 'JaVaScRiPt:alert(1)'}] | Scheme normalizes to lowercase `javascript:` before the allowlist check; no href is set; link renders as inert text "Click" |
| rich-content-019 | link-protocol-allowlist | items = [{type: 'link', label: 'Click', url: '  javascript:alert(1)'}] | Leading whitespace is stripped during URL parsing; scheme resolves to `javascript:`; no href is set; link renders as inert text "Click" |
| rich-content-020 | render-items-in-order | items = [] | Container renders with no child elements; no error or console warning |
| rich-content-021 | image-error-handling | items = [{type: 'image', src: 'https://example.com/image.png'}]; the load event then the error event fire in quick succession | Reveal happens once and stays revealed; no duplicate render, no thrown error |
| rich-content-022 | link-protocol-allowlist | items = [{type: 'link', label: 'Bad', url: 'ht!tp://invalid'}] | The `!` is not a legal scheme character, so resolving against the internal base restarts in relative mode and yields protocol `https:`; href is set to "ht!tp://invalid" and the link is clickable (see **Malformed-but-parseable URL passes through** in Edge Cases) |

