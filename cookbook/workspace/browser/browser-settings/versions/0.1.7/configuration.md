
The control table. Keys never change when a control moves
(`keys-never-change`); "new" marks a key this work adds.

| Topic | Group | Control | Key |
|-------|-------|---------|-----|
| General | User Agent | Custom user agent | `browser.custom_user_agent` |
| General | Media | Allow AirPlay | `browser.allows_airplay` |
| General | Web Inspector | Allow Web Inspector | `browser.web_inspector_enabled` |
| Behavior | Windows | Open sites in tabs (Settings window only) | `browser.new_opens_tabs` |
| Behavior | Page | Enable JavaScript | `browser.javascript_enabled` |
| Behavior | Page | Block pop-up windows | `browser.blocks_popups` |
| Behavior | Home Page | Address | `browser.home_page` |
| Behavior | Playback | Autoplay | `browser.autoplay` |
| Appearance | Page | Zoom | `browser.page_zoom` |
| Appearance | Page | Minimum font size | `browser.minimum_font_size` |
| Appearance | Tabs | Tab position (pane override) | `browser.tabs.positions` (new) |
| Privacy and Security | General | Pause all events (pane sheet only) | none — the pane's own state |
| Privacy and Security | General | Show privacy toolbar | `browser.privacy.show_toolbar` |
| Privacy and Security | Input | Disable keyboard events | `browser.privacy.keyboard` |
| Privacy and Security | Input | Disable mouse and scrolling events | `browser.privacy.mouse` |
| Privacy and Security | Input | Disable pointer tracking | `browser.privacy.pointer_tracking` |
| Privacy and Security | Input | Disable drag and drop | `browser.privacy.drag_and_drop` |
| Privacy and Security | Focus and visibility | Disable activation events | `browser.privacy.hide_activation` |
| Privacy and Security | Coding Partner | Agent access | `browser.privacy.agent_access` |
| Privacy and Security | Coding Partner | Agent while paused | `browser.privacy.agent_while_paused` |
| Privacy and Security | Agent Privacy | Conceal privacy words from agents | `browser.agent_privacy.enabled` |
| Privacy and Security | Agent Privacy | Hide Images | `browser.privacy.hide_images` |
| Privacy and Security | Storage | Cookie and storage jar | `browser.privacy.storage_jar` |
| Privacy and Security | Scripts | Third-party content | `browser.privacy.third_party_content` |
| Privacy and Security | Scripts | Capture page console | `browser.privacy.console_capture` |
| Privacy and Security | Cookies | Accept cookies | `browser.accepts_cookies` |
| Privacy and Security | Cookies | Private browsing (global only) | `browser.private_browsing` |
| Privacy and Security | Camera and Microphone | When a page asks | `browser.media_capture` |
| Privacy and Security | Protection | Warn about fraudulent websites | `browser.fraud_warning` |
| Privacy and Security | Protection | Upgrade known sites to HTTPS | `browser.upgrades_to_https` |
| Privacy and Security | Protection | Lockdown Mode | `browser.lockdown_mode` |
| Privacy and Security | Site Data | Manage Site Data… | none — opens the Site Data window |
| Privacy and Security | History | Record history | `browser.records_history` |
| Privacy and Security | History | Keep visits for (Settings window only) | `browser.history_retention` |
| Privacy and Security | History | Agent can see history | `browser.agent.history_access` (new, default None) |
| Downloads | Location | Folder, Choose Folder…, Use Downloads Folder | `browser.download_directory` |
| Downloads | Location | Ask where to save each file | `browser.asks_download_location` |
| Extensions | — | see the Extensions Settings Topic recipe | none |
| Chrome (compiled out) | Developer Tools, Performance | Allow developer tools; Remote debugging port; Use hardware acceleration | `browser.chrome.devtools_enabled`, `browser.chrome.remote_debugging_port`, `browser.chrome.hardware_acceleration` |
| Chrome Extensions (compiled out) | Updates | Check for updates | `browser.chrome.extension_update_interval` |
| Reset | — | Use Global Settings for This Pane; Reset Browser Settings… | none |

Topics no longer listed: History (its Recording group moved to Privacy and
Security › History; its visit list and Clear History… are the History
window's), Cookies (→ Privacy and Security › Cookies), Media and Permissions
(Playback → Behavior, Camera and Microphone → Privacy and Security), Safari
(Protection → Privacy and Security, Media › AirPlay and Web Inspector →
General, Site Data → the Site Data window).

