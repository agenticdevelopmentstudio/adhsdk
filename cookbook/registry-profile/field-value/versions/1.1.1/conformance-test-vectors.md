
| ID | Requirements | Input | Expected |
|----|-------------|-------|----------|
| field-value-001 | url-as-link, url-protocol-stripped, url-security-attributes | `{ type: 'url', value: 'https://example.com', label: 'Website' }` | `<a class="rp-field__link" href="https://example.com" rel="noopener noreferrer nofollow" target="_blank">example.com</a>` |
| field-value-002 | empty-text-renders-nothing | `{ type: 'text', value: '', label: 'Name' }` | `null` |
| field-value-003 | email-as-text | `{ type: 'email', value: 'user@example.com', label: 'Email' }` | `<span class="rp-field__text">user@example.com</span>` |
| field-value-004 | phone-as-text | `{ type: 'phone', value: '+1-555-1234', label: 'Phone' }` | `<span class="rp-field__text">+1-555-1234</span>` |
| field-value-005 | boolean-as-yes-no | `{ type: 'boolean', value: true, label: 'Active' }` | `<span class="rp-field__text">Yes</span>` |
| field-value-006 | boolean-as-yes-no | `{ type: 'boolean', value: false, label: 'Active' }` | `<span class="rp-field__text">No</span>` |
| field-value-007 | multi-select-as-list, multi-select-items-stringified | `{ type: 'multi_select', value: ['Option A', 'Option B'], label: 'Tags' }` | `<ul class="rp-field__tags"><li class="rp-field__tag">Option A</li><li class="rp-field__tag">Option B</li></ul>` |
| field-value-008 | empty-multi-select-renders-nothing | `{ type: 'multi_select', value: [], label: 'Tags' }` | `null` |
| field-value-009 | image-resolver-used, image-alt-text, image-class | `{ type: 'image', value: 'attachment-123', label: 'Profile Photo' }`, resolveImageUrl returns 'https://cdn.example.com/img/attachment-123.jpg' | `<img class="rp-field__image" src="https://cdn.example.com/img/attachment-123.jpg" alt="Profile Photo" />` |
| field-value-010 | unresolvable-image-renders-nothing | `{ type: 'image', value: 'missing-id', label: 'Photo' }`, resolveImageUrl returns null | `null` |
| field-value-011 | address-comma-separated, address-value-as-object | `{ type: 'address', value: { line1: '123 Main St', city: 'Springfield', country: 'USA' }, label: 'Address' }` | `<span class="rp-field__text">123 Main St, Springfield, USA</span>` |
| field-value-012 | empty-address-renders-nothing | `{ type: 'address', value: { line1: '', line2: '', city: '', region: '', postalCode: '', country: '' }, label: 'Address' }` | `null` |
| field-value-013 | markdown-as-text | `{ type: 'markdown', value: '# Hello\nWorld', label: 'Bio' }` | `<p class="rp-field__prose"># Hello\nWorld</p>` |
| field-value-014 | textarea-as-text | `{ type: 'textarea', value: 'Line 1\nLine 2', label: 'Notes' }` | `<p class="rp-field__prose">Line 1\nLine 2</p>` |
| field-value-015 | delivery-label-lookup | `{ type: 'text', value: 'in_person', label: 'Delivery' }` | `<span class="rp-field__text">In person</span>` |
| field-value-016 | delivery-label-lookup, unmapped-values-as-is | `{ type: 'text', value: 'custom-value', label: 'Delivery' }` | `<span class="rp-field__text">custom-value</span>` |
| field-value-017 | nullish-values-as-empty-string | `{ type: 'text', value: null, label: 'Optional' }` | `null` |
| field-value-018 | nullish-values-as-empty-string | `{ type: 'text', value: undefined, label: 'Optional' }` | `null` |
| field-value-019 | render-by-type, unmapped-values-as-is | `{ type: 'date', value: '2026-01-15', label: 'Start Date' }` | `<span class="rp-field__text">2026-01-15</span>` |
| field-value-020 | render-by-type, unmapped-values-as-is | `{ type: 'select', value: 'option-a', label: 'Status' }` | `<span class="rp-field__text">option-a</span>` |
| field-value-021 | url-protocol-stripped | `{ type: 'url', value: 'http://example.com', label: 'Website' }` | `<a class="rp-field__link" href="http://example.com" rel="noopener noreferrer nofollow" target="_blank">example.com</a>` |
| field-value-022 | url-as-link | `{ type: 'url', value: 'example.com/path', label: 'Website' }` | `<a class="rp-field__link" href="example.com/path" rel="noopener noreferrer nofollow" target="_blank">example.com/path</a>` |
| field-value-023 | image-resolver-used, unresolvable-image-renders-nothing | `{ type: 'image', value: 'attachment-1', label: 'Photo' }`, resolveImageUrl not provided | `null` |
| field-value-024 | address-comma-separated | `{ type: 'address', value: { line1: '123 Main St', region: 'CA', postalCode: '90210' }, label: 'Address' }` | `<span class="rp-field__text">123 Main St, CA, 90210</span>` |
| field-value-025 | empty-email-or-phone-renders-empty-span | `{ type: 'email', value: '', label: 'Email' }` | `<span class="rp-field__text"></span>` |
| field-value-026 | empty-email-or-phone-renders-empty-span | `{ type: 'phone', value: null, label: 'Phone' }` | `<span class="rp-field__text"></span>` |
| field-value-027 | markdown-as-text | `{ type: 'markdown', value: '<script>alert(1)</script>', label: 'Bio' }` | `<p class="rp-field__prose">&lt;script&gt;alert(1)&lt;/script&gt;</p>` |
| field-value-028 | boolean-as-yes-no | `{ type: 'boolean', value: 'false', label: 'Active' }` | `<span class="rp-field__text">Yes</span>` |
| field-value-029 | boolean-as-yes-no | `{ type: 'boolean', value: null, label: 'Active' }` | `<span class="rp-field__text">No</span>` |
| field-value-030 | url-as-link | `{ type: 'url', value: 'javascript:alert(1)', label: 'Website' }` | `<a class="rp-field__link" href="javascript:throw new Error('React has blocked a javascript: URL as a security precaution.')" rel="noopener noreferrer nofollow" target="_blank">javascript:alert(1)</a>` |

