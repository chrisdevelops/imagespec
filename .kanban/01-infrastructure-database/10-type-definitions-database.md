# Database Type Definitions

## Description
Generate TypeScript types from the database schema for type-safe database queries and ensure consistency between DB and application code.

## Dependencies
- [ ] 01-infrastructure-database/02-core-tables-migration.md

## Acceptance Criteria
- [ ] TypeScript types generated from Supabase schema
- [ ] Types exported from `src/lib/types/database.ts`
- [ ] Types include: User, SubscriptionTier, Collection, Image, ImageMetadata, AiResponse
- [ ] Enums defined for status values, orientation, etc.
- [ ] Types match database schema exactly
- [ ] Types re-generated after schema changes
- [ ] Documentation for regenerating types

## Technical Notes
- Generate types using Supabase CLI:
  ```bash
  supabase gen types typescript --local > src/lib/types/database.ts
  ```
- Or use online project:
  ```bash
  supabase gen types typescript --project-id <project-id> > src/lib/types/database.ts
  ```
- Add npm script to package.json:
  ```json
  "gen:types": "supabase gen types typescript --local > src/lib/types/database.ts"
  ```
- Types include Database interface with schema structure
- Use with Supabase client:
  ```typescript
  import { Database } from '@/lib/types/database';
  const supabase = createClient<Database>();
  const { data } = await supabase.from('images').select('*'); // fully typed
  ```
- Re-generate after any schema migration
- Consider adding to pre-commit hook or CI
- **GOTCHA**: Auto-generated types may need manual tweaks for complex JSONB fields
- Export helper types from index:
  ```typescript
  export type User = Database['public']['Tables']['users']['Row'];
  ```

## Architecture Reference
- CLAUDE.md: "Types in Separate Files" principle
- CLAUDE.md: File Organization section
