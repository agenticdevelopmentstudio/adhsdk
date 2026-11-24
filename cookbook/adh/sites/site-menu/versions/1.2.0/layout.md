
```
SIGNED OUT, ANY SITE OFF THE HUB'S   SIGNED IN, /home AND WORKSPACE ROUTES (hub)
WORKSPACE ROUTES (MarketingSiteMenu) (WorkspaceMenu replaces the site menu)
──────────────────                   ─────────────────────────────────────────
[search: Search sites, or browse     (a different component; see dispatch-workspace-swap)
 topics]                [? or gear]

SIGNED IN, `/` AND OTHER MARKETING ROUTES (MarketingSiteMenu)
SIGNED IN OR OUT, SATELLITE SITES    WorkspaceSiteMenu, signed in
─────────────────────────────────    ──────────────────────────────
[search ........................]    [search ........................]  [gear]
                                     (host nav rows, phone only)
(host nav rows, phone only)          [Home]   Home
[LogIn]    Login   (signed out)        [Boxes] Workspaces        flyout
[UserPlus] Sign up (signed out)      [Help]   Help
── section 0 / 1 divider ──          [History] Recents           flyout
[Bot]      Bitbag                    ── section 0 / 1 divider ──
[Hexagon]  Hub                       Bitbag, Messages, Hub (flyout),
[UsersRound] Dev Team                Organizations, Learn (flyout),
[ChefHat]  Cookbook                  Plan (header), Build (header),
[Wrench]   SDK                       Personas, Products, Hire (flyouts)
[UserCircle] Persona Registry        ── divider, admins only ──
── section 2 divider ──              Admin (flyout)
[CircleHelp] Help
[Mail]     Contact
── divider ──                        ── divider ──
   studio wordmark (footer)             studio wordmark (footer)
```

- Section 0 holds the auth top section and the Help row. Section 1 (`FLEET_SECTION`) holds Recents and the family tree. Section 2 holds the help block in the marketing tree and the Admin block in the workspace tree.
- Section 3 holds the host's own navigation rows (phone only), so a divider falls between them and the top section. A signed-out visitor on a hub workspace path sees `WorkspaceSiteMenu` with Login and Sign up above the family tree.
- The marketing tree omits Home, Workspaces and the chrome Help row, so a signed-in visitor on `/` sees the family rows and the Help and Contact block only, plus Recents when one exists.
- Row icons come from `menu-icons`; the glyph per site is listed there, not here.

