// Loaded with `node --import ./test/support/register.mjs` (see package.json "test").
// Installs the no-network resolve hook from loader.mjs and makes fetch() fail
// loudly, so a test can never reach a real server by accident.
import { registerHooks } from 'node:module'
import { resolve } from './loader.mjs'

registerHooks({ resolve })

globalThis.fetch = async function blockedFetch(input) {
  throw new Error(`network access is disabled in tests (fetch ${String(input)})`)
}
