# Image Card Component

## Description
Create reusable ImageCard component to display individual images in grids with thumbnail, status, and quick actions.

## Dependencies
- [ ] 05-images-crud/01-images-api-implementation.md

## Acceptance Criteria
- [ ] ImageCard component created in `src/components/images/ImageCard.tsx`
- [ ] Displays thumbnail image from CDN URL
- [ ] Shows processing status badge (processing/completed/failed)
- [ ] Hover actions: edit, delete, view
- [ ] Click opens image detail view
- [ ] Loading placeholder for images
- [ ] Error state for failed image loads
- [ ] Responsive design (adapts to grid)
- [ ] Accessibility (keyboard navigation, ARIA labels)
- [ ] TypeScript props interface

## Technical Notes
- Use shadcn Card component as base
- Image loading with Next.js Image component:
  ```tsx
  <Image
    src={image.cdn_url}
    alt={metadata?.alt_text || image.original_name}
    width={300}
    height={300}
    className="object-cover"
  />
  ```
- Status badges:
  - Processing: Spinner + "Processing..." (blue)
  - Completed: Checkmark (green)
  - Failed: X icon + "Failed" (red)
- Hover overlay with actions (edit, delete icons)
- Props interface:
  ```tsx
  interface ImageCardProps {
    image: Image;
    metadata?: ImageMetadata;
    onEdit?: () => void;
    onDelete?: () => void;
    onClick?: () => void;
  }
  ```
- **GOTCHA**: Handle missing CDN URLs gracefully
- **GOTCHA**: Show loading skeleton while image loads
- Use Intersection Observer for lazy loading in grid

## Architecture Reference
- ARCHITECTURE.md: Images Frontend Components
- CLAUDE.md: Component patterns and organization
