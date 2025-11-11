# Sign In Flow

## Description
Implement user sign-in with email/password, magic links, and OAuth providers. Handle session creation and redirect to dashboard.

## Dependencies
- [ ] 02-authentication/01-supabase-auth-client-setup.md

## Acceptance Criteria
- [ ] Login page/modal UI created
- [ ] Email/password login working
- [ ] Magic link login working
- [ ] Social OAuth login working
- [ ] "Remember me" functionality
- [ ] Password reset link on login page
- [ ] Success: redirect to dashboard or return URL
- [ ] Failure: show specific error messages
- [ ] Loading states during signin
- [ ] Form validation with Zod
- [ ] Rate limiting protection (via Supabase)
- [ ] Test: login creates valid session

## Technical Notes
- Create login page: `src/app/(auth)/login/page.tsx`
- Or create modal: `src/components/auth/LoginModal.tsx`
- Email/password login:
  ```typescript
  const { data, error } = await supabase.auth.signInWithPassword({
    email,
    password
  });
  ```
- Magic link:
  ```typescript
  const { error } = await supabase.auth.signInWithOtp({
    email,
    options: {
      shouldCreateUser: false // don't create if doesn't exist
    }
  });
  ```
- Handle return URL:
  ```typescript
  const searchParams = new URLSearchParams(window.location.search);
  const returnUrl = searchParams.get('returnUrl') || '/dashboard';
  router.push(returnUrl);
  ```
- Error messages:
  - "Invalid login credentials" → "Email or password incorrect"
  - "Email not confirmed" → "Please check your email to verify your account"
- **GOTCHA**: Supabase rate limits login attempts automatically
- **TODO**: Add "Forgot password?" link

## Architecture Reference
- ARCHITECTURE.md: Sign In Flow
- Supabase auth configuration
