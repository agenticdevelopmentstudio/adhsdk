
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none in source (a port should use `mail.alert.title`) | Mail | Alert title |
| none in source (a port should use `mail.alert.ok`) | OK | Alert button |

- **localization-support**: NEEDS REVIEW: Not implemented in source. The alert title and button are string literals with no localization lookup, and the model's message is passed through as the error's description; a decision on supported locales would settle whether these need keys.

