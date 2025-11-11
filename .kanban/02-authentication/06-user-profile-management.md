# User Profile Management

## Description
Create account settings page for users to view and update their profile information, email, and password.

## Dependencies
- [ ] 02-authentication/01-supabase-auth-client-setup.md
- [ ] 01-infrastructure-database/02-core-tables-migration.md

## Acceptance Criteria
- [ ] Account settings page created at `/account` or `/settings`
- [ ] Display user email and creation date
- [ ] Email change form with verification
- [ ] Password change form
- [ ] Display current subscription tier
- [ ] Display usage statistics (images used this period)
- [ ] Account deletion flow with confirmation
- [ ] All forms validated with Zod
- [ ] Success/error messages for all operations
- [ ] Loading states during updates

## Technical Notes
- Create page: `src/app/account/page.tsx`
- Fetch user data:
  ```typescript
  const { data: user } = await supabase.from('users').select('*').single();
  ```
- Change email:
  ```typescript
  const { error } = await supabase.auth.updateUser({
    email: newEmail
  });
  // Requires confirmation at both old and new email
  ```
- Change password:
  ```typescript
  const { error } = await supabase.auth.updateUser({
    password: newPassword
  });
  ```
- Delete account:
  ```typescript
  const { error } = await supabase.rpc('delete_user_account');
  // Note: Implement RPC for safe deletion with cascade
  ```
- Display subscription tier and quota from public.users join subscription_tiers
- **GOTCHA**: Email change requires double confirmation (old + new email)
- **GOTCHA**: Account deletion should soft-delete or archive, not hard-delete immediately
- **TODO**: Add profile picture upload (future enhancement)

## Architecture Reference
- ARCHITECTURE.md: User Profile Management
- Database schema: public.users table
