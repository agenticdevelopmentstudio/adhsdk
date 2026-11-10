
DefaultDocLink is a simple, injectable link component that wraps an HTML anchor element. It accepts a `to` prop for the destination path instead of the standard `href` attribute, allowing hosts to inject custom link behavior through a router adapter. This component serves as the default fallback for environments without a router (plain React apps, tests, Storybook stories), while router-aware applications (such as Next.js) can provide their own adapter via component injection.

