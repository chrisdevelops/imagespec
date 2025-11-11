# Plausible Analytics Setup

## Description
Set up Plausible for privacy-friendly website analytics.

## Dependencies
- None (infrastructure)

## Acceptance Criteria
- [ ] Plausible account created
- [ ] Domain configured
- [ ] Tracking script added to app
- [ ] Goals/events configured
- [ ] Custom properties set up
- [ ] Privacy policy updated
- [ ] Test tracking working

## Technical Notes
- Sign up at plausible.io
- Add tracking script to layout:
  ```tsx
  <Script
    defer
    data-domain="yourdomain.com"
    src="https://plausible.io/js/script.js"
  />
  ```
- Track events:
  ```typescript
  window.plausible('signup', { props: { tier: 'free' } });
  ```
- Configure goals in Plausible dashboard:
  - signup
  - login
  - upload_completed
  - subscription_created
- **GOTCHA**: GDPR compliant (no cookies)
- No PII tracking

## Architecture Reference
- ARCHITECTURE.md Section 12: Plausible Analytics
