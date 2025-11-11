# AWS S3 Bucket Configuration

## Description
Create and configure AWS S3 bucket for image storage with proper CORS, lifecycle policies, encryption, and IAM permissions.

## Dependencies
- None (can be done early)

## Acceptance Criteria
- [ ] S3 bucket created with descriptive name (e.g., `imagespec-images-production`)
- [ ] Bucket versioning enabled (optional, for recovery)
- [ ] Server-side encryption enabled (AES-256 or KMS)
- [ ] CORS configuration allows browser uploads from app domain
- [ ] Lifecycle policy configured for orphaned files cleanup
- [ ] Bucket not publicly listable
- [ ] IAM user created with minimal permissions (PutObject, GetObject, DeleteObject)
- [ ] Access keys generated and stored in secrets manager
- [ ] Test upload and download working

## Technical Notes
- Create bucket in AWS Console or via AWS CLI
- Bucket naming: `imagespec-images-{environment}` (production, staging, dev)
- Enable encryption at rest:
  ```json
  {
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }
  ```
- CORS configuration:
  ```json
  [{
    "AllowedHeaders": ["*"],
    "AllowedMethods": ["PUT", "POST", "GET"],
    "AllowedOrigins": ["https://yourdomain.com", "http://localhost:3000"],
    "ExposeHeaders": ["ETag"]
  }]
  ```
- IAM policy for app user:
  ```json
  {
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Action": ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"],
      "Resource": "arn:aws:s3:::imagespec-images-production/*"
    }]
  }
  ```
- Store credentials in `.env.production`:
  ```
  AWS_S3_BUCKET=imagespec-images-production
  AWS_REGION=us-east-1
  AWS_ACCESS_KEY_ID=xxx
  AWS_SECRET_ACCESS_KEY=xxx
  ```
- **GOTCHA**: Never make bucket publicly readable - use signed URLs or CloudFront
- **GOTCHA**: CORS must include localhost for local development

## Architecture Reference
- ARCHITECTURE.md Section 2: S3 + CloudFront for object storage + CDN
- ARCHITECTURE.md Section 4: Storage & CDN
