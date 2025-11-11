# Image Upload Component

## Description
Create the main upload component integrated with collections, combining file selection, quota checking, and upload initiation.

## Dependencies
- [ ] 05-images-crud/01-images-api-implementation.md
- [ ] 07-upload-flow/01-upload-queue-manager.md
- [ ] 07-upload-flow/02-file-dropzone-component.md

## Acceptance Criteria
- [ ] ImageUploader component created
- [ ] Integrated with collection selection
- [ ] Shows quota before upload
- [ ] File validation (type, size)
- [ ] Drag-and-drop support
- [ ] File browser support
- [ ] Bulk upload support (with tier limits)
- [ ] Shows upload queue and progress
- [ ] Handles upload errors
- [ ] Success: shows images in collection
- [ ] Disabled if quota exceeded

## Technical Notes
- Create component: `src/components/images/ImageUploader.tsx`
- Flow:
  1. Check quota via `/api/usage`
  2. Show quota warning if near limit
  3. File selection (drag-drop or browse)
  4. Validate files (type, size, count vs tier limit)
  5. Call upload queue manager
  6. Show progress for each file
  7. On completion, refresh image list
- Integration:
  ```tsx
  <ImageUploader
    collectionId={collectionId}
    onUploadComplete={(imageIds) => {
      // Refresh collection images
      // Show success toast
    }}
    onError={(error) => {
      // Show error toast
    }}
  />
  ```
- Tier limit enforcement:
  - Free: max 1 file at a time
  - Pro: max 20 files at a time
  - Get from user's subscription_tier features
- **GOTCHA**: Check total quota, not just bulk limit
- **GOTCHA**: Show clear error if quota exceeded before file selection

## Architecture Reference
- ARCHITECTURE.md Section 8: Upload flow
- User story: upload 1 vs 20 images based on tier
