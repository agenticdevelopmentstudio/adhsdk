import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // No transpilePackages: the @adh-sdk/* packages ship
  // prebuilt dist (compiled JS with "use client" preserved), so Next consumes
  // them like any normal library. The dist is built before next build (see
  // scripts/build.py).
  webpack: (config) => {
    // file: deps to the toolkit workspace are symlinked into node_modules;
    // without this, webpack walks into the symlink target and resolves peer
    // deps (react, react-dom) against the workspace tree instead of this
    // site's node_modules. Disabling preserves the consumer's resolution path.
    config.resolve = config.resolve ?? {};
    config.resolve.symlinks = false;
    return config;
  },
};

export default nextConfig;
