
`@adh-sdk/ui/blocks/add-users-modal`:

```ts
interface DraftUser { name: string; email: string; phone: string; note: string }
interface AddUsersModalProps {
  open: boolean
  onAdd: (users: DraftUser[]) => void
  onClose: () => void
  busy?: boolean
  title?: string        // default "Add users"
}
export function AddUsersModal(props: AddUsersModalProps): React.ReactElement
```

