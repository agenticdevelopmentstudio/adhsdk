
| Check | Status | Category |
|-------|--------|----------|
| [adc.check.accessibility.screen-reader-support](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/0720ed85-3747-546a-b2ed-6a909f44dd43) | partial | Accessibility |
| [adc.check.accessibility.contrast-ratio](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/a344a531-d87a-5c07-9e1d-747f8105bafa) | partial | Accessibility |
| [adc.check.internationalization.string-externalization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/79990a17-72ea-581d-b216-c50d6419e978) | partial | Internationalization |
| [adc.check.privacy-and-data.data-minimization](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/991d2adb-3f9a-524d-8218-529592614159) | passed | Privacy & Data |
| [adc.check.best-practices.separation-of-concerns](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/5ff14706-ab76-5c69-8a69-109919512b76) | passed | Best Practices |
| [adc.check.best-practices.unit-test-coverage](cookbook:00bf1936-4bb6-4ba2-ba0a-6fc9a3697cd0/8c0c971b-350f-55ee-90ef-78b3863de437) | partial | Best Practices |

`screen-reader-support` is `partial`: the component adds no accessible name,
text alternative, or table alternative for the plot; only the chart library's
default accessibility layer (focusable region, arrow-key tooltip navigation)
exposes the data beyond the visual chart and hover tooltip. `contrast-ratio` is `partial`: all
colours are theme tokens whose resolved values cannot be determined from the
component. `string-externalization` is `partial`: the only fixed literal is the
tooltip's em dash, and every other string comes from the caller.
`data-minimization` passes: the component only draws what it is given and keeps
nothing. `separation-of-concerns` passes: `time-series-chart.tsx` only
presents points and series supplied by the caller, holding no data fetching,
aggregation, or state. `unit-test-coverage` is `partial`: `timeSeriesChart.test.tsx`
covers one line per series with a legend naming each, colouring by position,
no legend for a single series, formatting y-axis ticks, and refusing a fifth
series; the null gap, the tooltip placeholder, and the default height are not
yet asserted by a test.

