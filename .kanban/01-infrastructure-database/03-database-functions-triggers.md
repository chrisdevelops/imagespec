# Database Functions and Triggers

## Description
Implement all database functions and triggers including auth sync, quota management RPCs, and auto-updated timestamps.

## Dependencies
- [ ] 01-infrastructure-database/02-core-tables-migration.md

## Acceptance Criteria
- [ ] `update_updated_at_column()` function created
- [ ] `handle_new_user()` function created with SECURITY DEFINER
- [ ] `on_auth_user_created` trigger created on auth.users table
- [ ] `check_and_reserve_slots()` RPC created with atomic FOR UPDATE
- [ ] `decrement_user_image_count()` RPC created for rollback
- [ ] `get_user_quota()` RPC created for read-only quota checks
- [ ] `increment_user_image_count()` RPC created (optional, see notes)
- [ ] updated_at triggers added to users, collections, images, image_metadata tables
- [ ] All functions tested with sample data
- [ ] Auth trigger creates public.users row on signup
- [ ] Concurrent quota reservation tested (no race conditions)

## Technical Notes
- File in: `supabase/migrations/partials/initial_schema/03_functions.sql` and `04_triggers.sql`
- Auth trigger requires SECURITY DEFINER to write to public schema
- `check_and_reserve_slots()` uses FOR UPDATE to prevent race conditions:
  ```sql
  SELECT ... FROM users WHERE id = p_user_id FOR UPDATE
  ```
- Returns: `{ success: boolean, used: int, quota_limit: int, remaining: int }`
- If quota_limit = -1, quota is unlimited
- Decrement function: `GREATEST(images_used_this_period - p_count, 0)` to prevent negatives
- Test auth trigger: create user via Supabase Auth, verify public.users row exists
- **GOTCHA**: Trigger must handle COALESCE for auth.users.updated_at (may not exist)
- **GOTCHA**: Use service_role or DB owner role to create trigger on auth.users

## Architecture Reference
- Section 3.2: Idempotent user sync function & trigger
- Section 3.4: Atomic reserve RPC
- Section 3.5: Decrement (rollback) RPC
- Section 3.6: Optional convenience quota read
