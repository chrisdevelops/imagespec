# Quota Rollback Implementation

## Description
Implement quota rollback logic to decrement user quota when uploads or processing fail, ensuring accurate quota tracking.

## Dependencies
- [ ] 06-quota-management/01-quota-rpcs-implementation.md
- [ ] 08-processing-pipeline/04-processing-webhook-endpoint.md

## Acceptance Criteria
- [ ] Rollback called when upload fails after reservation
- [ ] Rollback called when processing fails
- [ ] Rollback called when user cancels upload
- [ ] decrement_user_image_count() RPC used correctly
- [ ] Rollback amount matches reserved amount
- [ ] Logging of all rollback operations
- [ ] Error handling if rollback fails
- [ ] Test rollback scenarios

## Technical Notes
- Rollback scenarios:
  1. **Upload failure**: User reserved quota but S3 upload failed
  2. **Processing failure**: Processing job failed permanently
  3. **User cancellation**: User cancelled upload mid-flight
  4. **Validation failure**: File invalid after reservation
- Implementation in upload flow:
  ```typescript
  try {
    // Reserve quota
    const reservation = await checkAndReserveSlots(userId, count);
    if (!reservation.success) {
      return { error: 'Quota exceeded' };
    }

    // Generate upload URLs
    const uploadUrls = await generateUploadUrls(files);

    // Upload to S3
    await uploadToS3(files, uploadUrls);

    // Complete upload
    await completeUpload(imageIds);
  } catch (error) {
    // Rollback on any failure
    await decrementUserImageCount(userId, count);
    throw error;
  }
  ```
- Implementation in processing pipeline:
  ```typescript
  // In /api/jobs/process-image
  try {
    // Process image
    await processImage(imageId);

    // Update status to completed
    await updateImageStatus(imageId, 'completed');
  } catch (error) {
    // Update status to failed
    await updateImageStatus(imageId, 'failed');

    // Rollback quota
    await decrementUserImageCount(userId, 1);

    // Log error
    logger.error('Processing failed', { imageId, error });
  }
  ```
- Cancellation handling:
  ```typescript
  const handleCancelUpload = async (imageId: string) => {
    // Abort upload
    abortController.abort();

    // Rollback quota
    await fetch('/api/quota/rollback', {
      method: 'POST',
      body: JSON.stringify({ count: 1 })
    });
  };
  ```
- Create API endpoint: `POST /api/quota/rollback`
  - Calls decrement_user_image_count()
  - Returns updated quota
  - Requires authentication
- **GOTCHA**: Don't rollback twice for same failure
- **GOTCHA**: Log all rollbacks for debugging
- **GOTCHA**: Rollback should never go below 0 (handled by RPC)
- Consider idempotency key to prevent duplicate rollbacks

## Architecture Reference
- ARCHITECTURE.md Section 3.5: Decrement (rollback) RPC
- ARCHITECTURE.md Section 6: Failure Handling
- ARCHITECTURE.md: "call decrement_user_image_count to rollback quota"
