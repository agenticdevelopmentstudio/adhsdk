
Privacy Level Select is a controlled form component that allows users to choose a privacy level from three options: "Only me" (private to user), "Hub members" (visible to organization members), or "Public" (visible to internet). The component renders a button trigger displaying the current selection and icon, with a popover menu containing the full list. A fourth disabled option ("Team / Org") signals upcoming functionality. The component manages keyboard navigation internally and requires the parent to handle privacy persistence via the `onChange` callback.

