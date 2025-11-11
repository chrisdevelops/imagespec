# Upload Error Handling

## Description
Implement comprehensive error handling for all upload failure scenarios with clear user messaging and retry logic.

## Dependencies
- [ ] 07-upload-flow/01-upload-queue-manager.md

## Acceptance Criteria
- [ ] All upload error scenarios handled
- [ ] User-friendly error messages (not technical)
- [ ] Retry logic for transient failures (network errors)
- [ ] Max retry attempts (3 times)
- [ ] Exponential backoff between retries
- [ ] No retry for permanent failures (invalid file, quota exceeded)
- [ ] Error logging to Sentry with context
- [ ] Visual feedback for errors
- [ ] Bulk upload continues despite individual failures
- [ ] Summary of failures shown at end

## Technical Notes
- Error scenarios to handle:
  1. **Network failure** - Retry automatically
  2. **S3 upload failure** - Retry
  3. **Quota exceeded** - Don't retry, show upgrade
  4. **Invalid file type/size** - Don't retry, show validation error
  5. **Server error (5xx)** - Retry with backoff
  6. **Authentication error** - Don't retry, redirect to login
  7. **S3 signature expired** - Request new signature, retry
  8. **Upload cancelled by user** - Don't retry
- Create error handler: `src/lib/upload/errorHandler.ts`
  ```typescript
  export enum UploadErrorType {
    NETWORK_ERROR = 'network_error',
    QUOTA_EXCEEDED = 'quota_exceeded',
    INVALID_FILE = 'invalid_file',
    SERVER_ERROR = 'server_error',
    AUTH_ERROR = 'auth_error',
    SIGNATURE_EXPIRED = 'signature_expired',
    UNKNOWN = 'unknown'
  }

  export interface UploadError {
    type: UploadErrorType;
    message: string;
    retryable: boolean;
    originalError: Error;
  }

  export function classifyUploadError(error: Error): UploadError {
    // Network errors
    if (error.message.includes('Failed to fetch') || error.message.includes('Network')) {
      return {
        type: UploadErrorType.NETWORK_ERROR,
        message: 'Network error. Check your connection and try again.',
        retryable: true,
        originalError: error
      };
    }

    // Quota errors (from API response)
    if (error.message.includes('quota') || error.message.includes('limit')) {
      return {
        type: UploadErrorType.QUOTA_EXCEEDED,
        message: 'Upload limit reached. Upgrade to Pro for more uploads.',
        retryable: false,
        originalError: error
      };
    }

    // ... classify other errors

    return {
      type: UploadErrorType.UNKNOWN,
      message: 'Upload failed. Please try again.',
      retryable: true,
      originalError: error
    };
  }

  export async function retryWithBackoff<T>(
    fn: () => Promise<T>,
    maxAttempts: number = 3
  ): Promise<T> {
    for (let attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await fn();
      } catch (error) {
        const uploadError = classifyUploadError(error as Error);

        // Don't retry non-retryable errors
        if (!uploadError.retryable || attempt === maxAttempts) {
          throw uploadError;
        }

        // Exponential backoff: 2^attempt seconds
        const delay = Math.pow(2, attempt) * 1000;
        await new Promise(resolve => setTimeout(resolve, delay));

        console.log(`Retry attempt ${attempt} after ${delay}ms`);
      }
    }
    throw new Error('Max retries exceeded');
  }
  ```
- Usage in upload queue:
  ```typescript
  const uploadFile = async (file: File, uploadUrl: string) => {
    try {
      await retryWithBackoff(async () => {
        await uploadToS3(file, uploadUrl);
      }, 3);

      // Mark as completed
      updateUploadStatus(file.name, 'completed');
    } catch (error) {
      const uploadError = error as UploadError;

      // Log to Sentry
      Sentry.captureException(uploadError.originalError, {
        tags: { upload_error_type: uploadError.type },
        extra: { fileName: file.name, fileSize: file.size }
      });

      // Update UI
      updateUploadStatus(file.name, 'failed');
      setUploadError(file.name, uploadError.message);

      // Show toast for non-retryable errors
      if (!uploadError.retryable) {
        toast.error(uploadError.message);
      }
    }
  };
  ```
- Error summary component:
  ```tsx
  interface UploadSummaryProps {
    succeeded: number;
    failed: Array<{ fileName: string; error: string }>;
  }

  function UploadSummary({ succeeded, failed }: UploadSummaryProps) {
    if (failed.length === 0) {
      return <Alert><AlertTitle>All uploads completed!</AlertTitle></Alert>;
    }

    return (
      <Alert variant="destructive">
        <AlertTitle>{succeeded} succeeded, {failed.length} failed</AlertTitle>
        <AlertDescription>
          <ul className="list-disc list-inside">
            {failed.map(f => (
              <li key={f.fileName}>{f.fileName}: {f.error}</li>
            ))}
          </ul>
        </AlertDescription>
      </Alert>
    );
  }
  ```
- **GOTCHA**: Don't retry indefinitely
- **GOTCHA**: Log all errors for debugging
- **GOTCHA**: Show actionable error messages (e.g., "Upgrade" button for quota)

## Architecture Reference
- ARCHITECTURE.md Section 4: Upload Error Handling
- ARCHITECTURE.md Section 8: Error recovery
