# Create Collection Modal

## Description
Implement modal dialog for creating new collections with form validation and error handling.

## Dependencies
- [ ] 04-collections-crud/01-collections-api-implementation.md

## Acceptance Criteria
- [ ] Modal opens from "New Collection" button
- [ ] Form with name and description fields
- [ ] Real-time form validation with Zod
- [ ] Submit creates collection via API
- [ ] Success: close modal and refresh list
- [ ] Error: show error message in modal
- [ ] Loading state during submission
- [ ] Mobile-responsive

## Technical Notes
- Create component: `src/components/collections/CreateCollectionModal.tsx`
- Use shadcn Dialog component
- Form validation with Zod schema
- Use React Hook Form for form management
- Optimistic UI update: add to list immediately
- Clear form on successful submit
- Focus name input when modal opens

## Architecture Reference
- ARCHITECTURE.md: CreateCollectionModal component
- CLAUDE.md: Forms & Inputs patterns
