# Storage Utilities and Helpers

## Description
Create utility functions for storage operations including file validation, S3 key generation, CloudFront URL construction, and file deletion.

## Dependencies
- [ ] 03-storage-setup/01-aws-s3-bucket-configuration.md
- [ ] 03-storage-setup/02-cloudfront-cdn-setup.md

## Acceptance Criteria
- [ ] File validation utility (MIME type, size, dimensions)
- [ ] S3 key generation function (UUID-based, organized by date)
- [ ] CloudFront URL construction function
- [ ] S3 file deletion function
- [ ] Image compression utility (optional, pre-upload)
- [ ] File exists check function (HEAD request)
- [ ] All utilities have TypeScript types
- [ ] Unit tests for all utilities

## Technical Notes
- Create utilities file: `src/lib/storage/utils.ts`
- File validation:
  ```typescript
  const ALLOWED_TYPES = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
  const MAX_SIZE = 10 * 1024 * 1024; // 10MB

  export function validateImageFile(file: File): { valid: boolean; error?: string } {
    if (!ALLOWED_TYPES.includes(file.type)) {
      return { valid: false, error: 'Invalid file type. Only JPEG, PNG, WebP, and GIF allowed.' };
    }
    if (file.size > MAX_SIZE) {
      return { valid: false, error: `File too large. Maximum size is ${MAX_SIZE / 1024 / 1024}MB.` };
    }
    return { valid: true };
  }
  ```
- Generate S3 key:
  ```typescript
  export function generateS3Key(filename: string, userId: string): string {
    const date = new Date();
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const uuid = crypto.randomUUID();
    const ext = filename.split('.').pop();
    return `uploads/${year}/${month}/${userId}/${uuid}.${ext}`;
  }
  ```
- CloudFront URL:
  ```typescript
  export function getCloudFrontUrl(s3Key: string): string {
    return `https://${process.env.CLOUDFRONT_DOMAIN}/${s3Key}`;
  }
  ```
- Delete from S3:
  ```typescript
  import { DeleteObjectCommand } from '@aws-sdk/client-s3';
  export async function deleteFromS3(key: string): Promise<void> {
    await s3Client.send(new DeleteObjectCommand({
      Bucket: process.env.AWS_S3_BUCKET!,
      Key: key
    }));
  }
  ```
- **GOTCHA**: Organize S3 keys by date for easier lifecycle management
- **TODO**: Add image optimization/compression before upload (Sharp or browser-based)

## Architecture Reference
- ARCHITECTURE.md Section 4: Storage Utilities
- CLAUDE.md: Utility functions organization
