# Job Enqueue Utility

## Description
Create utility function to enqueue processing jobs to QStash with idempotency.

## Dependencies
- [ ] 08-processing-pipeline/01-qstash-configuration.md

## Acceptance Criteria
- [ ] enqueueProcessingJob() function created
- [ ] Uses QStash SDK or REST API
- [ ] Includes imageId and attempt counter
- [ ] Idempotency key prevents duplicates
- [ ] Error handling for QStash API errors
- [ ] Logging of enqueue operations
- [ ] Returns job ID

## Technical Notes
- Install QStash SDK: `npm install @upstash/qstash`
- Create utility: `src/lib/queue/enqueueJob.ts`
  ```typescript
  import { Client } from '@upstash/qstash';

  const qstash = new Client({ token: process.env.QSTASH_TOKEN! });

  export async function enqueueProcessingJob(imageId: string) {
    const result = await qstash.publishJSON({
      url: `${process.env.APP_URL}/api/jobs/process-image`,
      body: { imageId, attempt: 0 },
      headers: {
        'Idempotency-Key': `process-${imageId}`
      }
    });
    return result.messageId;
  }
  ```
- **GOTCHA**: Use Idempotency-Key to prevent duplicate jobs
- Log to Sentry on enqueue failure

## Architecture Reference
- ARCHITECTURE.md Section 6: Job Enqueue Implementation
