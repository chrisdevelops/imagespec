# Collection Detail View

## Description
Create full-page view for individual collection showing all images, metadata, and collection actions.

## Dependencies
- [ ] 04-collections-crud/01-collections-api-implementation.md
- [ ] 05-images-crud/01-images-api-implementation.md

## Acceptance Criteria
- [ ] Page at /collections/[id]
- [ ] Display collection name and description
- [ ] Show all images in grid
- [ ] Edit and delete collection buttons
- [ ] Image count and storage stats
- [ ] Upload button prominent
- [ ] Export collection button
- [ ] Loading state while fetching
- [ ] 404 if collection not found

## Technical Notes
- Create page: `src/app/collections/[id]/page.tsx`
- Server component for initial data fetch
- Use shadcn Breadcrumb for navigation
- Image grid with lazy loading
- Handle empty collection (no images yet)
- Add realtime subscription for new images

## Architecture Reference
- ARCHITECTURE.md: CollectionDetailView component
- Next.js dynamic routing
