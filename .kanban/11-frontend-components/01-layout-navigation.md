# Layout and Navigation

## Description
Create core layout components including header, sidebar, and responsive navigation.

## Dependencies
- [ ] 02-authentication/04-session-management.md

## Acceptance Criteria
- [ ] AppLayout component with sidebar
- [ ] Header with user menu
- [ ] Sidebar navigation with active states
- [ ] Mobile navigation drawer
- [ ] Responsive design
- [ ] Logo and branding
- [ ] User avatar and dropdown
- [ ] Logout functionality

## Technical Notes
- Create: `src/components/layout/AppLayout.tsx`
- Use shadcn components (Sheet for mobile nav)
- Navigation items:
  - Dashboard
  - Collections
  - Account
  - Billing
- Show current usage in sidebar
- **GOTCHA**: Mobile-first responsive design
- Active link highlighting

## Architecture Reference
- ARCHITECTURE.md: Layout & Navigation
- CLAUDE.md: Component patterns
