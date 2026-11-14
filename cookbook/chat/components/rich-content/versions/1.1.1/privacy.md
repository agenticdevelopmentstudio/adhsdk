
- **Data collected**: None. The component does not collect, log, or transmit any user data.
- **URL handling**: URLs provided in content items are not modified, validated against a server, or transmitted anywhere outside of the component's rendering context. The component does not make network requests beyond the browser's standard image loading for image items.
- **Image-fetch exposure**: Because image `src` values are fetched unconditionally (hiding an image does not delay its fetch, per **hide-until-loaded**), rendering an item whose `src` points at an attacker-controlled host discloses the viewer's IP address and User-Agent to that host and can act as a tracking beacon or read-receipt, the same as any `<img>` tag pointed at an arbitrary URL. This is standard browser image-loading behavior, not a data-sharing action the component itself performs, and there is no scheme allowlist on `src` (unlike `url` on links).

