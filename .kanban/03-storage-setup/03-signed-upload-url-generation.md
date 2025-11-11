# Signed Upload URL Generation

## Description
Implement server-side function to generate presigned S3 PUT URLs allowing browser to upload directly to S3 without exposing AWS credentials.

## Dependencies
- [ ] 03-storage-setup/01-aws-s3-bucket-configuration.md

## Acceptance Criteria
- [ ] S3 client utility created in `src/lib/storage/s3Client.ts`
- [ ] Function to generate presigned PUT URLs
- [ ] URLs expire after 15 minutes
- [ ] Content-type restriction in signature
- [ ] File size limit in signature
- [ ] Unique S3 keys generated (UUID-based)
- [ ] Function tested with actual S3 upload
- [ ] Error handling for AWS SDK errors

## Technical Notes
- Install AWS SDK: `npm install @aws-sdk/client-s3 @aws-sdk/s3-request-presigner`
- Create S3 client: `src/lib/storage/s3Client.ts`
  ```typescript
  import { S3Client } from '@aws-sdk/client-s3';

  export const s3Client = new S3Client({
    region: process.env.AWS_REGION!,
    credentials: {
      accessKeyId: process.env.AWS_ACCESS_KEY_ID!,
      secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY!
    }
  });
  ```
- Generate presigned URL:
  ```typescript
  import { PutObjectCommand } from '@aws-sdk/client-s3';
  import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

  export async function generateUploadUrl(filename: string, contentType: string) {
    const key = `uploads/${crypto.randomUUID()}-${filename}`;
    const command = new PutObjectCommand({
      Bucket: process.env.AWS_S3_BUCKET!,
      Key: key,
      ContentType: contentType
    });
    const uploadUrl = await getSignedUrl(s3Client, command, { expiresIn: 900 }); // 15 min
    return { uploadUrl, key };
  }
  ```
- Validate content type (only allow images)
- Add file size limit via API endpoint validation (before generating URL)
- **GOTCHA**: Presigned URLs expose bucket name but not AWS credentials
- **GOTCHA**: Client must use same content-type in PUT request as in signature
- **TODO**: Add checksum for upload integrity verification

## Architecture Reference
- ARCHITECTURE.md Section 5: Signed PUTs for uploads (direct-to-S3)
- ARCHITECTURE.md Section 4: Upload URL Generation
