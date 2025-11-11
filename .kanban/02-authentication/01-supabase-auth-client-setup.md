# Supabase Auth Client Setup

## Description
Set up Supabase authentication client for browser, server, and middleware contexts with proper cookie handling for Next.js App Router.

## Dependencies
- [ ] 01-infrastructure-database/01-initial-database-setup.md

## Acceptance Criteria
- [ ] Browser client created in `src/lib/supabase/client.ts` (already exists)
- [ ] Server client created in `src/lib/supabase/server.ts` (already exists)
- [ ] Middleware client created in `src/lib/supabase/middleware.ts` (already exists)
- [ ] Middleware configured in `src/middleware.ts` (already exists)
- [ ] All three clients tested and working
- [ ] Session persistence working across page refreshes
- [ ] Cookie handling working in Server Components
- [ ] Auth state accessible in client components

## Technical Notes
- Files already exist but verify implementation:
  - `src/lib/supabase/client.ts` - uses `createBrowserClient` from `@supabase/ssr`
  - `src/lib/supabase/server.ts` - uses `createServerClient` with cookies()
  - `src/lib/supabase/middleware.ts` - uses `updateSession` for auth refresh
- Middleware matcher pattern excludes static files and images
- Server client handles cookies.get/set/remove for SSR
- Browser client uses NEXT_PUBLIC env vars
- **GOTCHA**: Server Components must use async createClient() from server.ts
- **GOTCHA**: Client Components use synchronous createClient() from client.ts
- Test auth state:
  ```typescript
  const supabase = createClient();
  const { data: { user } } = await supabase.auth.getUser();
  ```

## Architecture Reference
- CLAUDE.md: "Supabase Client Patterns"
- Existing files in src/lib/supabase/
