# Image Detail View

## Description
Create full-page view for individual image showing full-size image, complete metadata, and all available actions.

## Dependencies
- [ ] 05-images-crud/01-images-api-implementation.md
- [ ] 05-images-crud/06-metadata-display-component.md

## Acceptance Criteria
- [ ] Page at `/images/[id]` or modal view
- [ ] Full-size image display with zoom capability
- [ ] All metadata displayed (description, alt text, keywords, colors, etc.)
- [ ] Edit metadata button
- [ ] Regenerate metadata button
- [ ] Delete image button
- [ ] Download original button
- [ ] Copy CDN URL button
- [ ] Back to collection navigation
- [ ] Loading state while fetching
- [ ] 404 if image not found
- [ ] Share functionality (optional)

## Technical Notes
- Create page: `src/app/images/[id]/page.tsx` OR modal component
- Fetch image with metadata:
  ```tsx
  const { data: image } = await supabase
    .from('images')
    .select('*, image_metadata(*)')
    .eq('id', id)
    .single();
  ```
- Image display with lightbox/zoom:
  - Use library like react-medium-image-zoom
  - Or implement custom zoom with transform
- Metadata sections:
  - Description & Alt Text
  - Keywords (as tags)
  - Colors (color palette display)
  - Technical info (dimensions, size, format)
  - Focal point visualization
  - Style tags and mood
  - Suggested use cases
- Action buttons in header or sidebar
- **GOTCHA**: Check ownership via RLS before showing edit/delete
- **GOTCHA**: Disable regenerate if processing
- Subscribe to realtime updates for status changes

## Architecture Reference
- ARCHITECTURE.md: Image Detail View
- User story: view generated metadata
