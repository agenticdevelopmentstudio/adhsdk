
DocMetadata is a stateless display component that renders document frontmatter fields in a right-aligned definition list. Each field is a `DocMetadataField`:

```ts
interface DocMetadataField {
  label: ReactNode
  value: ReactNode
}
```

`value` is typed `ReactNode`, which already admits arrays. The component detects `Array.isArray(value)`: only an actual array triggers the wrapping flex group; every other value, including a non-array iterable, renders inline as-is. The component renders nothing when the fields array is empty.

