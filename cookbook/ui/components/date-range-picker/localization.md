
| String Key | Default (en) | Context |
|-----------|-------------|---------|
| none (literal) | From | Label of the first field |
| none (literal) | To | Label of the second field |

- **string-externalization**: NEEDS REVIEW: Not implemented in source. The two labels are literal English strings and no prop supplies a translation; label props or a string table would be needed, and the owner's localization approach for shared web components would settle which.

The displayed date format and the calendar popup language are the browser's, from the user's locale; the value crossing the component boundary is always `YYYY-MM-DD`.

