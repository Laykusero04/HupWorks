// Synchronous Node resolve hook for the test suite (registered by register.mjs).
// No network: it only redirects imports.
//  - '@supabase/supabase-js' -> supabase-stub.mjs (fake client factory, fake-supabase.ts)
//  - './supabase' imported by src/lib/adminApi.ts -> browser-supabase-stub.mjs
//    (the real module reads import.meta.env, which Node does not provide)
//  - extensionless relative imports (the app uses bundler resolution) -> '.ts'
import { existsSync } from 'node:fs'
import path from 'node:path'
import { fileURLToPath, pathToFileURL } from 'node:url'

const here = path.dirname(fileURLToPath(import.meta.url))
const SUPABASE_STUB = pathToFileURL(path.join(here, 'supabase-stub.mjs')).href
const BROWSER_STUB = pathToFileURL(path.join(here, 'browser-supabase-stub.mjs')).href

export function resolve(specifier, context, nextResolve) {
  if (specifier === '@supabase/supabase-js') {
    return { url: SUPABASE_STUB, shortCircuit: true, format: 'module' }
  }
  if (
    specifier === './supabase' &&
    context.parentURL &&
    context.parentURL.endsWith('/src/lib/adminApi.ts')
  ) {
    return { url: BROWSER_STUB, shortCircuit: true, format: 'module' }
  }
  if (
    (specifier.startsWith('./') || specifier.startsWith('../')) &&
    context.parentURL &&
    path.extname(specifier) === ''
  ) {
    const candidate = path.resolve(path.dirname(fileURLToPath(context.parentURL)), specifier + '.ts')
    if (existsSync(candidate)) {
      return { url: pathToFileURL(candidate).href, shortCircuit: true }
    }
  }
  return nextResolve(specifier, context)
}
