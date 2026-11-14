
Applicable: the DTO can include email addresses, phone numbers, and physical
addresses, all personal data. All privacy gating — deciding which of these
fields a given viewer may see — is enforced server-side before the DTO is
constructed (see **No client-side privacy gating** in Design Decisions).
`UserCard` itself does not collect, store, or transmit this data; it only
renders whatever fields are present in the DTO it receives.

