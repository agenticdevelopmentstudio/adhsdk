import { featureVitest } from '../vitest.preset'

// No setup file of its own: nothing here keeps module-scope state between tests, so the
// shared root setup is enough.
export default featureVitest()
