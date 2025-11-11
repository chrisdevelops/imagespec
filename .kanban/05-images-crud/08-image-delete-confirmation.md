# Image Delete Confirmation

## Description
Implement confirmation dialog for deleting images with warning about permanent deletion.

## Dependencies
- [ ] 05-images-crud/01-images-api-implementation.md

## Acceptance Criteria
- [ ] Confirmation dialog before delete
- [ ] Shows image thumbnail in dialog
- [ ] Warning about permanent deletion
- [ ] "Cancel" and "Delete" buttons
- [ ] Delete button is destructive style (red)
- [ ] Success: remove from UI and show toast
- [ ] Error: show error message
- [ ] Loading state during deletion
- [ ] Optional: quota rollback consideration

## Technical Notes
- Create component: `src/components/images/DeleteImageConfirmation.tsx`
- Use shadcn AlertDialog for confirmation
- Dialog content:
  - Small thumbnail of image
  - Warning message: "Are you sure you want to delete this image? This action cannot be undone."
  - Show original filename
  - Optional: show if metadata exists
- Delete flow:
  1. Show confirmation dialog
  2. User confirms
  3. Call DELETE `/api/images/[id]`
  4. On success:
     - Remove from local state/cache
     - Show success toast
     - Optional: call decrement quota (if policy allows)
  5. On error:
     - Show error message
     - Keep dialog open
- Implementation:
  ```tsx
  const handleDelete = async () => {
    setIsDeleting(true);
    try {
      const response = await fetch(`/api/images/${imageId}`, {
        method: 'DELETE'
      });
      if (!response.ok) throw new Error('Delete failed');
      onDeleteSuccess();
      toast.success('Image deleted successfully');
    } catch (error) {
      toast.error('Failed to delete image');
    } finally {
      setIsDeleting(false);
    }
  };
  ```
- **GOTCHA**: S3 deletion happens in API, not client
- **GOTCHA**: ON DELETE CASCADE removes metadata automatically
- **TODO**: Consider soft delete for recovery (future enhancement)

## Architecture Reference
- ARCHITECTURE.md: DELETE /api/images/[id] endpoint
- CLAUDE.md: Confirmation dialogs pattern
