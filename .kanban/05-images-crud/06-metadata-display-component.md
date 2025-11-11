# Metadata Display Component

## Description
Create read-only metadata display component showing all generated AI metadata in an organized, visual format.

## Dependencies
- [ ] 05-images-crud/01-images-api-implementation.md
- [ ] 01-infrastructure-database/10-type-definitions-database.md

## Acceptance Criteria
- [ ] MetadataDisplay component created
- [ ] All metadata fields displayed
- [ ] Organized into logical sections
- [ ] Color palette visual representation
- [ ] Focal point visualization overlay
- [ ] Tags displayed as chips
- [ ] Copy-to-clipboard for text fields
- [ ] Responsive layout
- [ ] Loading state
- [ ] Empty state for missing metadata

## Technical Notes
- Create component: `src/components/images/MetadataDisplay.tsx`
- Sections to display:
  1. **Description & Alt Text**
     - Description (full text)
     - Alt text (highlighted for copy)
  2. **Keywords**
     - Display as tag chips
     - Copy all button
  3. **Color Palette**
     - Show dominant colors as swatches
     - Display hex codes
     - Show palette mood and overall tone
  4. **Visual Properties**
     - Dimensions (width x height)
     - Aspect ratio
     - Orientation
     - Visual weight
     - Background complexity
     - Negative space
  5. **Style & Mood**
     - Style tags (as chips)
     - Mood tags (as chips)
     - Formality level
  6. **Composition**
     - Focal point (with visual indicator on image)
     - Subject type
     - Text overlay safety
     - Safe text zones (visual overlay)
  7. **Suggested Uses**
     - Use cases (as list items)
- Component structure:
  ```tsx
  interface MetadataDisplayProps {
    metadata: ImageMetadata;
    imageUrl?: string; // for focal point overlay
    compact?: boolean; // compact view for cards
  }
  ```
- Use shadcn components: Card, Badge, Separator
- **GOTCHA**: Some fields may be null - handle gracefully
- **GOTCHA**: Focal point overlay should be toggle-able

## Architecture Reference
- ARCHITECTURE.md: MetadataDisplay component
- User story: view generated metadata
- Database schema: image_metadata table
