# Collections List Component

## Description
Create CollectionsList component to display user's collections in grid/list view with loading states and empty state.

## Dependencies
- [ ] 04-collections-crud/01-collections-api-implementation.md

## Acceptance Criteria
- [ ] CollectionsList component displays all collections
- [ ] Grid and list view toggle
- [ ] Collection cards show name, description, image count, thumbnail
- [ ] Loading skeleton while fetching
- [ ] Empty state when no collections
- [ ] Responsive design (mobile-first)
- [ ] TypeScript props interface
- [ ] Integrates with collections API

## Technical Notes
- Create component: `src/components/collections/CollectionsList.tsx`
- Fetch collections using React Query or SWR
- Collection card preview: show first 4 images as thumbnail grid
- Empty state CTA: "Create your first collection"
- Use shadcn Card component
- Handle loading and error states gracefully
- Use Suspense boundaries for better UX

## Architecture Reference
- ARCHITECTURE.md: Collections Frontend Components
- CLAUDE.md: Component patterns
