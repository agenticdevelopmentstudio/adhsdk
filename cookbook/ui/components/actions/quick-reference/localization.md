
String content (title, triggerLabel, ariaLabel, entry labels, syntax) is provided entirely by the consumer; the component renders no hard-coded UI strings. The component sets no explicit `dir` attribute on the `dd`/`code` elements that hold syntax examples: under an RTL-locale ancestor, syntax such as `**text**` inherits `rtl` directionality and can reorder unexpectedly, since the source applies no bidi isolation to code content (see [adc.check.internationalization.rtl-layout-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/f81d57a5-fd2a-5088-9fea-37703287698d)).

