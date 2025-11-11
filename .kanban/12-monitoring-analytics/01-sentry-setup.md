# Sentry Setup

## Description
Set up Sentry for error tracking and performance monitoring across the application.

## Dependencies
- None (infrastructure)

## Acceptance Criteria
- [ ] Sentry project created
- [ ] @sentry/nextjs installed
- [ ] sentry.client.config.js configured
- [ ] sentry.server.config.js configured
- [ ] sentry.edge.config.js configured
- [ ] DSN stored in environment variables
- [ ] Sample rates configured
- [ ] Source maps upload configured
- [ ] Error boundary added to app
- [ ] Test error tracking working

## Technical Notes
- Install: `npm install @sentry/nextjs`
- Create Sentry project at sentry.io
- Run: `npx @sentry/wizard@latest -i nextjs`
- Configure client:
  ```javascript
  Sentry.init({
    dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
    environment: process.env.NODE_ENV,
    tracesSampleRate: 0.1,
    replaysSessionSampleRate: 0.1,
    replaysOnErrorSampleRate: 1.0
  });
  ```
- Set user context: `Sentry.setUser({ id: userId })`
- **GOTCHA**: Use hashed user IDs for privacy
- Upload source maps in CI

## Architecture Reference
- ARCHITECTURE.md Section 12: Sentry Integration
