
- **Data collected**: a selector and a label of at most 60 characters of
  the picked element's text, stored locally in the hidden-items store; the
  label can hold page text and is never sent anywhere.
- **Exposure to the page**: none from the picker. Its script, finder and
  outline live in the `adk-element-picker` world (MUST, see
  `isolated-content-world`); the page cannot read the picks. The page can
  observe that its clicks stop arriving while selecting.
- **Agent exposure**: none; the picker sends nothing to any agent.

