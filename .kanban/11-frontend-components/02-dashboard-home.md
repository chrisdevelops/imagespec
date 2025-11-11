# Dashboard Home

## Description
Create dashboard home page with stats, recent collections, and quick actions.

## Dependencies
- [ ] 11-frontend-components/01-layout-navigation.md

## Acceptance Criteria
- [ ] Dashboard page at /dashboard
- [ ] Usage statistics widget
- [ ] Recent collections quick access
- [ ] Upload quick action button
- [ ] Activity feed (recent uploads)
- [ ] Responsive layout
- [ ] Loading states
- [ ] Empty states

## Technical Notes
- Create: `src/app/dashboard/page.tsx`
- Stats to show:
  - Images used this period
  - Quota remaining
  - Total collections
  - Total images
- Recent collections: last 5
- Activity feed: last 10 uploads
- Use shadcn Card for widgets
- **GOTCHA**: Real-time updates via Supabase Realtime

## Architecture Reference
- ARCHITECTURE.md: Dashboard components
