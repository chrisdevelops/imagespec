# Storage Type Definitions

## Description
Define TypeScript types and interfaces for all storage-related operations, configurations, and state management.

## Dependencies
- [ ] 03-storage-setup/03-signed-upload-url-generation.md

## Acceptance Criteria
- [ ] UploadUrlResponse type defined
- [ ] UploadProgress type defined
- [ ] UploadState type/enum defined
- [ ] S3Config type defined
- [ ] CloudFrontConfig type defined
- [ ] StorageError type defined
- [ ] All types exported from `src/lib/types/storage.ts`
- [ ] Types used consistently across storage utilities

## Technical Notes
- Create types file: `src/lib/types/storage.ts`
  ```typescript
  export interface UploadUrlResponse {
    uploadUrl: string;
    s3Key: string;
    expiresAt: Date;
  }

  export interface UploadProgress {
    loaded: number;
    total: number;
    percentage: number;
    speed?: number; // bytes per second
    estimatedTimeRemaining?: number; // seconds
  }

  export enum UploadState {
    IDLE = 'idle',
    UPLOADING = 'uploading',
    COMPLETED = 'completed',
    FAILED = 'failed',
    CANCELLED = 'cancelled'
  }

  export interface S3Config {
    bucket: string;
    region: string;
    accessKeyId: string;
    secretAccessKey: string;
  }

  export interface CloudFrontConfig {
    domain: string;
    distributionId: string;
  }

  export interface StorageError {
    code: string;
    message: string;
    retryable: boolean;
  }

  export interface FileValidationResult {
    valid: boolean;
    error?: string;
  }
  ```
- Re-export from main types index:
  ```typescript
  // src/lib/types/index.ts
  export * from './storage';
  ```
- Use Zod schemas for runtime validation (optional):
  ```typescript
  import { z } from 'zod';
  export const uploadUrlResponseSchema = z.object({
    uploadUrl: z.string().url(),
    s3Key: z.string(),
    expiresAt: z.date()
  });
  ```
- **GOTCHA**: Keep types in sync with actual implementation
- **TODO**: Add JSDoc comments for complex types

## Architecture Reference
- CLAUDE.md: "Types in Separate Files" principle
- ARCHITECTURE.md: Type Definitions sections
