# Sign Up Flow

## Description
Implement user signup with email/password, magic links, and social OAuth providers (Google, GitHub). Verify that signup triggers public.users row creation.

## Dependencies
- [ ] 01-infrastructure-database/03-database-functions-triggers.md
- [ ] 02-authentication/01-supabase-auth-client-setup.md

## Acceptance Criteria
- [ ] Signup page/modal UI created
- [ ] Email/password signup working
- [ ] Magic link signup working
- [ ] Google OAuth signup working (optional for MVP)
- [ ] GitHub OAuth signup working (optional for MVP)
- [ ] Email confirmation flow handled
- [ ] Success: redirect to dashboard
- [ ] Failure: show error message
- [ ] Loading states during signup
- [ ] Form validation with Zod
- [ ] Auth trigger creates public.users row
- [ ] Test: signup creates both auth.users and public.users rows

## Technical Notes
- Create signup page: `src/app/(auth)/signup/page.tsx`
- Or create modal: `src/components/auth/SignupModal.tsx`
- Email/password signup:
  ```typescript
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      emailRedirectTo: `${location.origin}/auth/callback`
    }
  });
  ```
- Magic link signup:
  ```typescript
  const { error } = await supabase.auth.signInWithOtp({
    email,
    options: {
      emailRedirectTo: `${location.origin}/auth/callback`
    }
  });
  ```
- OAuth signup:
  ```typescript
  const { error } = await supabase.auth.signInWithOAuth({
    provider: 'google',
    options: {
      redirectTo: `${location.origin}/auth/callback`
    }
  });
  ```
- Verify trigger: Query public.users after signup
- **GOTCHA**: Email confirmation required by default in Supabase config
- **GOTCHA**: OAuth providers need to be enabled in Supabase dashboard
- Password requirements: min 6 chars (configurable in Supabase)

## Architecture Reference
- ARCHITECTURE.md: Authentication & User Management
- supabase/config.toml: Auth configuration
