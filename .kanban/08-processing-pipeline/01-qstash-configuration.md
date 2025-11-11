# QStash Configuration

## Description
Set up Upstash QStash for job queue management with proper retry logic and dead letter queue.

## Dependencies
- None (infrastructure setup)

## Acceptance Criteria
- [ ] Upstash account created
- [ ] QStash project created
- [ ] Signing key obtained and stored
- [ ] Job format defined: {imageId, attempt}
- [ ] Retry policy configured (3 attempts, exponential backoff)
- [ ] Dead letter queue configured
- [ ] Timeout limits set
- [ ] Environment variables configured

## Technical Notes
- Sign up at upstash.com
- Create QStash project
- Store in .env:
  ```
  QSTASH_URL=https://qstash.upstash.io
  QSTASH_TOKEN=xxx
  QSTASH_CURRENT_SIGNING_KEY=xxx
  QSTASH_NEXT_SIGNING_KEY=xxx
  ```
- Default retry: 3 attempts with 2^n second delays
- Configure webhook URL: `https://yourdomain.com/api/jobs/process-image`
- **GOTCHA**: Webhook must validate QStash signature

## Architecture Reference
- ARCHITECTURE.md Section 6: QStash Configuration
