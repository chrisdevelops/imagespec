# Client-Side Upload Implementation

## Description
Implement browser-based direct upload to S3 using presigned URLs with progress tracking, cancellation, and retry logic.

## Dependencies
- [ ] 03-storage-setup/03-signed-upload-url-generation.md

## Acceptance Criteria
- [ ] Upload utility created in `src/lib/storage/uploadToS3.ts`
- [ ] Direct PUT to S3 using presigned URL
- [ ] Upload progress tracking (percentage)
- [ ] Upload cancellation support via AbortController
- [ ] Retry on network failures (max 3 attempts, exponential backoff)
- [ ] Error handling for all failure scenarios
- [ ] TypeScript types for upload state and progress
- [ ] Test: upload various file sizes and types
- [ ] Test: cancellation works correctly

## Technical Notes
- Create upload utility: `src/lib/storage/uploadToS3.ts`
  ```typescript
  export async function uploadToS3(
    file: File,
    uploadUrl: string,
    onProgress?: (progress: number) => void,
    signal?: AbortSignal
  ): Promise<void> {
    return new Promise((resolve, reject) => {
      const xhr = new XMLHttpRequest();

      xhr.upload.addEventListener('progress', (e) => {
        if (e.lengthComputable && onProgress) {
          const progress = (e.loaded / e.total) * 100;
          onProgress(progress);
        }
      });

      xhr.addEventListener('load', () => {
        if (xhr.status === 200) resolve();
        else reject(new Error(`Upload failed: ${xhr.status}`));
      });

      xhr.addEventListener('error', () => reject(new Error('Upload failed')));

      if (signal) {
        signal.addEventListener('abort', () => {
          xhr.abort();
          reject(new Error('Upload cancelled'));
        });
      }

      xhr.open('PUT', uploadUrl);
      xhr.setRequestHeader('Content-Type', file.type);
      xhr.send(file);
    });
  }
  ```
- Implement retry logic with exponential backoff:
  ```typescript
  async function uploadWithRetry(file: File, uploadUrl: string, maxRetries = 3) {
    for (let i = 0; i < maxRetries; i++) {
      try {
        await uploadToS3(file, uploadUrl);
        return;
      } catch (error) {
        if (i === maxRetries - 1) throw error;
        await new Promise(resolve => setTimeout(resolve, 2 ** i * 1000));
      }
    }
  }
  ```
- **GOTCHA**: Must use XMLHttpRequest (not fetch) for upload progress tracking
- **GOTCHA**: Content-Type header must match presigned URL parameters
- Calculate upload speed: track bytes/sec for ETA display

## Architecture Reference
- ARCHITECTURE.md Section 4: Client-Side Upload
- ARCHITECTURE.md: Upload flow details
