
Known gap, not "not applicable". All user-facing text (aria-label, title tooltip) is hardcoded in English and derived from the mode values. A parent application wishing to localize this text would need to wrap the component or use a custom implementation. The string-externalization and no-hardcoded-strings checks fail for this reason; see the pending localization Design Decision.
