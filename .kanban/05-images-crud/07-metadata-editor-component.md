# Metadata Editor Component

## Description
Create editable metadata form component allowing users to manually update any metadata field with validation.

## Dependencies
- [ ] 05-images-crud/01-images-api-implementation.md
- [ ] 05-images-crud/06-metadata-display-component.md

## Acceptance Criteria
- [ ] MetadataEditor component created
- [ ] All metadata fields editable
- [ ] Form validation with Zod
- [ ] Save button updates via PATCH API
- [ ] Cancel button reverts changes
- [ ] Dirty state indicator (unsaved changes)
- [ ] Loading state during save
- [ ] Success/error feedback
- [ ] Keyboard shortcuts (Cmd+S to save, Esc to cancel)
- [ ] Mobile-friendly form layout

## Technical Notes
- Create component: `src/components/images/MetadataEditor.tsx`
- Use React Hook Form for form management
- Zod validation schema matching database constraints:
  ```tsx
  const metadataSchema = z.object({
    description: z.string().min(1),
    alt_text: z.string().min(1),
    content_keywords: z.array(z.string()),
    dominant_colors: z.object({...}),
    palette_mood: z.string(),
    // ... all other fields
  });
  ```
- Form fields by type:
  - Text: description, alt_text
  - Text array: content_keywords, style_tags, mood, safe_text_zones, suggested_use_cases
  - Select: orientation, visual_weight, formality_level, subject_type, background_complexity, negative_space
  - Number: width, height (read-only)
  - Boolean: text_overlay_safe
  - JSONB: dominant_colors (complex color picker)
- Tag input for arrays:
  - Use shadcn TagInput or custom component
  - Allow adding/removing items
- Color palette editor:
  - Visual color picker for each dominant color
  - Hex input fallback
- Update API call:
  ```tsx
  const response = await fetch(`/api/images/${imageId}`, {
    method: 'PATCH',
    body: JSON.stringify(metadata)
  });
  ```
- **GOTCHA**: Validate before submit (dimensions must match constraints)
- **GOTCHA**: Warn user about unsaved changes before leaving
- Show "Modified by user" badge after manual edit

## Architecture Reference
- ARCHITECTURE.md: MetadataEditor component
- User story: edit any metadata field and save changes
- CLAUDE.md: Forms & Inputs patterns
