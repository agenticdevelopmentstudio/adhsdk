import { featureTsup } from '../tsup.preset'

// `topics` is a SECOND entry: the barrel's chunk carries `use client`, and the topic list is plain
// data the site's server-rendered console layout imports, so it needs an entry of its own.
export default featureTsup(['src/index.ts', 'src/product-admin-topics.ts'])
