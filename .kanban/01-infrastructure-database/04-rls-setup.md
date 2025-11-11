# Row-Level Security (RLS) Setup

## Description
Enable RLS on all tables and create policies to ensure users can only access their own data, enforcing security at the database level.

## Dependencies
- [ ] 01-infrastructure-database/02-core-tables-migration.md

## Acceptance Criteria
- [ ] RLS enabled on users, collections, images, image_metadata, subscription_tiers tables
- [ ] Users SELECT policy: `auth.uid() = id`
- [ ] Collections SELECT/INSERT/UPDATE/DELETE policies with `auth.uid() = user_id` check
- [ ] Images SELECT/INSERT/UPDATE/DELETE policies check ownership via collections join
- [ ] Image_metadata SELECT/INSERT/UPDATE/DELETE policies check ownership via images→collections join
- [ ] Subscription_tiers SELECT policy allows authenticated users
- [ ] All policies tested with different user contexts
- [ ] Test: User A cannot access User B's data
- [ ] Test: Unauthenticated users cannot access any data
- [ ] Service role can bypass RLS for admin operations

## Technical Notes
- File in: `supabase/migrations/partials/initial_schema/05_rls_enable.sql` and `06-10_rls_policies_*.sql`
- Enable RLS: `ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;`
- Policy pattern for collections:
  ```sql
  CREATE POLICY "Users can view own collections"
  ON public.collections FOR SELECT
  USING (auth.uid() = user_id);
  ```
- Policy pattern for images (via join):
  ```sql
  USING (
    auth.uid() IN (
      SELECT user_id FROM public.collections
      WHERE id = images.collection_id
    )
  )
  ```
- Test with Supabase client (uses anon key + RLS)
- Test with service_role client (bypasses RLS)
- **GOTCHA**: Policies on images/metadata use subquery joins - ensure indexes exist for performance
- **GOTCHA**: Service role bypasses RLS - only use server-side

## Architecture Reference
- Section 3.8: RLS basics
- Section 10: Security & RLS (operational)
- ARCHITECTURE.md lines 205-373 (full RLS policies)
