
This recipe is a headless authentication client: eleven dependency-free
modules that together give a host application a bearer-token session backed
by a same-origin, cookie-based refresh mechanism, cross-site single sign-on
against a shared authorization server (the AS), MFA/WebAuthn completion (both
at login time and in self-serve account security), and an authenticated
request wrapper the rest of the app builds on. It has no visual surface of
its own — every UI component in the auth family (login forms, callback pages,
account-security screens) is a consumer of this contract, not part of it.


A twelfth, React-based module covers a second kind of session. The product admin console (phase 6, now under `/admin` on each product's own site), where a product's own admins manage that product at its own host, keeps its access token in memory only, with its refresh token as an HttpOnly cookie on the site's origin. Its provider takes the path of the site's auth route handlers as a required `authBase` prop, installs an access-token source that the request wrapper and the refresh operation ask before storage, so every data client sends the site's bearer unchanged; with no source installed, nothing differs.

The client entry point (`client.ts`, published as `@adh-sdk/auth/client`) also re-exports the /v1 wire helpers, among them the token-free `publicJson` and `listAllPublicV1`, which are specified in the Auth v1 Wire Conventions ([adhsdk.ingredient.data.services.auth.v1](cookbook:870c182f-1a80-4254-8fec-3eb35c8f13f7)) recipe, not here.
