# CloudFront CDN Setup

## Description
Configure AWS CloudFront distribution to serve images from S3 with caching, SSL, and optional signed URLs for access control.

## Dependencies
- [ ] 03-storage-setup/01-aws-s3-bucket-configuration.md

## Acceptance Criteria
- [ ] CloudFront distribution created with S3 as origin
- [ ] Origin Access Control (OAC) configured to restrict S3 to CloudFront
- [ ] HTTPS/SSL certificate configured (use AWS Certificate Manager)
- [ ] Cache behaviors configured with appropriate TTL (1 day default)
- [ ] Custom domain configured (optional for MVP)
- [ ] Signed URLs working for private content (optional)
- [ ] Compression enabled (gzip, brotli)
- [ ] Test: images serve via CloudFront URL
- [ ] CDN domain stored in environment variables

## Technical Notes
- Create distribution in AWS Console or via CDN
- Origin settings:
  - Origin Domain: Select S3 bucket
  - Origin Access: Origin Access Control (OAC)
  - Update S3 bucket policy to allow CloudFront OAC
- Default cache behavior:
  - Viewer Protocol Policy: Redirect HTTP to HTTPS
  - Allowed HTTP Methods: GET, HEAD, OPTIONS
  - Cache TTL: 86400 seconds (1 day)
  - Compress Objects: Yes
- Invalidation for cache purging:
  ```bash
  aws cloudfront create-invalidation --distribution-id E123456 --paths "/*"
  ```
- Store CloudFront domain in env:
  ```
  CLOUDFRONT_DOMAIN=d111111abcdef8.cloudfront.net
  CLOUDFRONT_DISTRIBUTION_ID=E123456
  ```
- Generate CDN URLs in app:
  ```typescript
  const cdnUrl = `https://${process.env.CLOUDFRONT_DOMAIN}/${s3Key}`;
  ```
- **GOTCHA**: OAC replaces deprecated Origin Access Identity (OAI)
- **GOTCHA**: S3 bucket policy must allow CloudFront service principal
- **TODO**: Set up custom domain and SSL certificate (future)

## Architecture Reference
- ARCHITECTURE.md Section 2: CloudFront for CDN
- ARCHITECTURE.md Section 10: Configure CloudFront to restrict S3 access
