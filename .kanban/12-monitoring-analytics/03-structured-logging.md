# Structured Logging

## Description
Implement structured logging utility for application logs.

## Dependencies
- None (foundation)

## Acceptance Criteria
- [ ] Logger utility created
- [ ] Log levels: error, warn, info, debug
- [ ] JSON format output
- [ ] Context included (user, action, timestamp)
- [ ] Sanitization of sensitive data
- [ ] Integration with Sentry for errors
- [ ] Used across application

## Technical Notes
- Install winston or pino: `npm install pino`
- Create: `src/lib/utils/logger.ts`
  ```typescript
  import pino from 'pino';

  export const logger = pino({
    level: process.env.LOG_LEVEL || 'info',
    formatters: {
      level: (label) => ({ level: label })
    }
  });

  export function logStructured(level: string, message: string, context?: object) {
    logger[level]({ ...context, timestamp: new Date().toISOString() }, message);
  }
  ```
- Log key operations:
  - API requests
  - Upload start/complete
  - Processing job start/complete
  - Quota operations
  - Billing events
- **GOTCHA**: Sanitize passwords, tokens, keys
- Send errors to Sentry automatically

## Architecture Reference
- ARCHITECTURE.md Section 12: Application Logging
