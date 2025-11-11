# Upload Queue Manager

## Description
Implement client-side upload queue manager for handling multiple concurrent uploads with progress tracking.

## Dependencies
- [ ] 03-storage-setup/04-client-side-upload-implementation.md
- [ ] 05-images-crud/01-images-api-implementation.md
- [ ] 06-quota-management/02-quota-checking-api.md

## Acceptance Criteria
- [ ] UploadQueueManager class/hook created
- [ ] Handles multiple files simultaneously (max 5 concurrent)
- [ ] Tracks progress for each file
- [ ] Supports cancellation per file
- [ ] Retry failed uploads
- [ ] Quota check before starting uploads
- [ ] Updates UI in real-time
- [ ] Cleans up completed uploads

## Technical Notes
- Create: `src/lib/upload/UploadQueueManager.ts`
- Use React hooks for state management
- Queue structure:
  ```typescript
  interface UploadItem {
    id: string;
    file: File;
    status: UploadState;
    progress: number;
    error?: string;
    abortController?: AbortController;
  }
  ```
- Limit concurrent uploads using queue
- Call preupload API for each file
- Upload to S3 with progress callbacks
- Call complete API after S3 success
- **GOTCHA**: Check quota for entire batch before starting
- **GOTCHA**: Rollback quota on upload failure

## Architecture Reference
- ARCHITECTURE.md Section 5: Upload flow
- ARCHITECTURE.md Section 8: Client UX flows
