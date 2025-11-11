# Upload Type Definitions

## Description
Define comprehensive TypeScript types for upload states, progress tracking, queue management, and error handling.

## Dependencies
- [ ] 03-storage-setup/06-storage-type-definitions.md

## Acceptance Criteria
- [ ] UploadState enum defined
- [ ] UploadItem interface defined
- [ ] UploadProgress interface defined
- [ ] UploadResults interface defined
- [ ] UploadError interface defined
- [ ] Queue management types
- [ ] All types exported from `src/lib/types/upload.ts`
- [ ] Zod schemas for validation

## Technical Notes
- Create types file: `src/lib/types/upload.ts`
- Core types:
  ```typescript
  export enum UploadState {
    IDLE = 'idle',
    PENDING = 'pending',
    UPLOADING = 'uploading',
    PROCESSING = 'processing', // S3 upload done, API call pending
    COMPLETED = 'completed',
    FAILED = 'failed',
    CANCELLED = 'cancelled',
    PAUSED = 'paused'
  }

  export interface UploadProgress {
    loaded: number;
    total: number;
    percentage: number;
    speed?: number; // bytes per second
    eta?: number; // seconds remaining
    startTime: number;
    endTime?: number;
  }

  export interface UploadItem {
    id: string;
    file: File;
    imageId?: string; // Set after preupload
    uploadUrl?: string; // Presigned URL
    s3Key?: string;
    state: UploadState;
    progress: UploadProgress;
    error?: UploadError;
    abortController?: AbortController;
    retryCount: number;
    createdAt: Date;
    completedAt?: Date;
  }

  export interface UploadQueue {
    items: UploadItem[];
    maxConcurrent: number;
    activeCount: number;
    isPaused: boolean;
  }

  export interface UploadResults {
    total: number;
    succeeded: number;
    failed: number;
    successfulUploads: Array<{ id: string; imageId: string; name: string }>;
    failedUploads: Array<{ id: string; name: string; error: string }>;
    duration: number; // milliseconds
  }
  ```
- Error types (extended from storage):
  ```typescript
  export enum UploadErrorType {
    NETWORK_ERROR = 'network_error',
    QUOTA_EXCEEDED = 'quota_exceeded',
    INVALID_FILE = 'invalid_file',
    FILE_TOO_LARGE = 'file_too_large',
    INVALID_FILE_TYPE = 'invalid_file_type',
    SERVER_ERROR = 'server_error',
    AUTH_ERROR = 'auth_error',
    SIGNATURE_EXPIRED = 'signature_expired',
    S3_ERROR = 's3_error',
    CANCELLED = 'cancelled',
    UNKNOWN = 'unknown'
  }

  export interface UploadError {
    type: UploadErrorType;
    message: string;
    retryable: boolean;
    originalError?: Error;
    details?: Record<string, any>;
  }
  ```
- Callback types:
  ```typescript
  export type OnProgressCallback = (progress: UploadProgress) => void;
  export type OnCompleteCallback = (item: UploadItem) => void;
  export type OnErrorCallback = (item: UploadItem, error: UploadError) => void;
  export type OnStateChangeCallback = (item: UploadItem, oldState: UploadState) => void;

  export interface UploadCallbacks {
    onProgress?: OnProgressCallback;
    onComplete?: OnCompleteCallback;
    onError?: OnErrorCallback;
    onStateChange?: OnStateChangeCallback;
  }
  ```
- Queue manager options:
  ```typescript
  export interface UploadQueueOptions {
    maxConcurrent?: number; // default 5
    maxRetries?: number; // default 3
    autoStart?: boolean; // default true
    collectionId: string;
  }
  ```
- Zod schemas:
  ```typescript
  import { z } from 'zod';

  export const uploadItemSchema = z.object({
    id: z.string().uuid(),
    file: z.instanceof(File),
    imageId: z.string().uuid().optional(),
    state: z.nativeEnum(UploadState),
    retryCount: z.number().int().min(0).max(10)
  });
  ```
- Type guards:
  ```typescript
  export function isUploadActive(item: UploadItem): boolean {
    return [
      UploadState.PENDING,
      UploadState.UPLOADING,
      UploadState.PROCESSING
    ].includes(item.state);
  }

  export function isUploadComplete(item: UploadItem): boolean {
    return [
      UploadState.COMPLETED,
      UploadState.FAILED,
      UploadState.CANCELLED
    ].includes(item.state);
  }

  export function canRetryUpload(item: UploadItem): boolean {
    return item.state === UploadState.FAILED &&
           item.error?.retryable === true &&
           item.retryCount < 3;
  }
  ```
- Re-export from main types:
  ```typescript
  // src/lib/types/index.ts
  export * from './upload';
  ```
- **GOTCHA**: Keep consistent with storage types
- **GOTCHA**: Validate state transitions

## Architecture Reference
- CLAUDE.md: Types in Separate Files
- ARCHITECTURE.md Section 4: Upload types
