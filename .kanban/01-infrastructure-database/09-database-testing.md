# Database Testing

## Description
Create comprehensive tests for database functions, triggers, RLS policies, and quota management under concurrent load.

## Dependencies
- [ ] 01-infrastructure-database/03-database-functions-triggers.md
- [ ] 01-infrastructure-database/04-rls-setup.md

## Acceptance Criteria
- [ ] Unit tests for `check_and_reserve_slots()` RPC
- [ ] Unit tests for `decrement_user_image_count()` RPC
- [ ] Unit tests for `get_user_quota()` RPC
- [ ] Integration test for auth trigger creating public.users
- [ ] RLS policy tests with multiple user contexts
- [ ] Concurrent quota reservation test (10+ simultaneous requests)
- [ ] Test quota rollback on processing failure
- [ ] Test unlimited quota handling (quota_limit = -1)
- [ ] Test updated_at triggers fire correctly
- [ ] All tests passing in CI

## Technical Notes
- Create test file: `src/tests/database/quota-management.test.ts`
- Use Supabase test database or local instance
- Test framework: Jest or Vitest
- Create test users via Supabase Auth API
- Test concurrent reservations:
  ```typescript
  const promises = Array(10).fill(null).map(() =>
    supabase.rpc('check_and_reserve_slots', { p_user_id: userId, p_count: 1 })
  );
  const results = await Promise.all(promises);
  // Verify only quota_limit reservations succeeded
  ```
- Test RLS with different auth contexts:
  ```typescript
  const client1 = createClient(user1Token);
  const client2 = createClient(user2Token);
  // Verify user2 cannot see user1's collections
  ```
- Mock race conditions with small delays
- **GOTCHA**: Use FOR UPDATE in tests to verify lock behavior
- Run tests before each deployment

## Architecture Reference
- Section 3.4: Atomic reserve RPC
- Section 10: Security & RLS (operational)
- ARCHITECTURE.md user story: "atomic DB reserve RPC"
