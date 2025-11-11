# Password Reset Flow

## Description
Implement password reset functionality allowing users to reset their password via email link.

## Dependencies
- [ ] 02-authentication/01-supabase-auth-client-setup.md

## Acceptance Criteria
- [ ] "Forgot password?" link on login page
- [ ] Password reset request page created
- [ ] Email sent with reset link
- [ ] Password reset confirmation page created
- [ ] New password form with validation
- [ ] Password strength indicator
- [ ] Success: redirect to login with confirmation message
- [ ] Failure: show error message
- [ ] Reset link expiry handled (1 hour default)
- [ ] Test full flow: request → email → reset → login

## Technical Notes
- Create pages:
  - `src/app/(auth)/forgot-password/page.tsx` - request reset
  - `src/app/(auth)/reset-password/page.tsx` - set new password
- Request password reset:
  ```typescript
  const { error } = await supabase.auth.resetPasswordForEmail(email, {
    redirectTo: `${location.origin}/reset-password`
  });
  ```
- Handle reset (on reset-password page):
  ```typescript
  const { error } = await supabase.auth.updateUser({
    password: newPassword
  });
  ```
- Password validation:
  - Min 8 characters (recommended, Supabase default is 6)
  - At least one uppercase
  - At least one number
  - At least one special character
- Use Zod schema for validation
- **GOTCHA**: Reset link is single-use and expires in 1 hour (configurable)
- **TODO**: Add password strength meter (zxcvbn library)

## Architecture Reference
- Supabase Auth password reset documentation
- supabase/config.toml: password requirements
