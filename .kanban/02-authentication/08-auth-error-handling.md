# Authentication Error Handling

## Description
Implement comprehensive error handling for all authentication flows with user-friendly error messages and proper logging.

## Dependencies
- [ ] 02-authentication/02-signup-flow.md
- [ ] 02-authentication/03-signin-flow.md
- [ ] 02-authentication/05-password-reset-flow.md

## Acceptance Criteria
- [ ] All Supabase auth errors caught and handled
- [ ] User-friendly error messages (not raw error codes)
- [ ] Specific errors for common cases (invalid credentials, email exists, etc.)
- [ ] Retry logic for transient network failures
- [ ] All auth errors logged to Sentry with context
- [ ] Error messages match app tone and style
- [ ] Toast notifications for auth errors
- [ ] Form-level error display
- [ ] Network offline detection and message

## Technical Notes
- Create error mapping utility: `src/lib/auth/errorMessages.ts`
  ```typescript
  export function getAuthErrorMessage(error: AuthError): string {
    switch (error.message) {
      case 'Invalid login credentials':
        return 'Email or password is incorrect. Please try again.';
      case 'Email not confirmed':
        return 'Please verify your email address before signing in.';
      case 'User already registered':
        return 'An account with this email already exists.';
      // ... more cases
      default:
        return 'An error occurred. Please try again later.';
    }
  }
  ```
- Log to Sentry with context:
  ```typescript
  Sentry.captureException(error, {
    tags: { auth_flow: 'signup' },
    user: { email: email }
  });
  ```
- Implement retry for network errors (max 3 attempts)
- Show toast notification for errors: use shadcn toast component
- **GOTCHA**: Don't expose security-sensitive information in error messages
- **GOTCHA**: Rate limit errors should show "Too many attempts, please try again later"

## Architecture Reference
- CLAUDE.md: Error handling patterns
- ARCHITECTURE.md: Error Handling section
