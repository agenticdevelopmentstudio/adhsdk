
- **Data collected**: the site patterns, CSS selectors and short labels of
  items the user chose to hide from themselves or from an agent. A label
  is a trimmed piece of the picked element's text and may carry page
  content.
- **Storage**: one local SQLite file in the app's home directory; never
  transmitted, never synced between devices.
- **Retention**: until the user removes the entry or the file is deleted.
- **Agent exposure**: this component is not an agent surface; the agent
  list exists to keep content from agents.

