# Webhook Signature Validation

## Description
Implement QStash signature validation in processing webhook endpoint for security.

## Dependencies
- [ ] 08-processing-pipeline/01-qstash-configuration.md

## Acceptance Criteria
- [ ] Signature validation implemented
- [ ] Invalid signatures rejected with 401
- [ ] Uses both current and next signing keys
- [ ] Replay attack prevention
- [ ] Logging of validation failures
- [ ] Test with QStash CLI

## Technical Notes
- QStash sends signature in headers:
  - `Upstash-Signature`: current key signature
  - `Upstash-Signature-Next`: next key signature (during rotation)
- Validation:
  ```typescript
  import { Receiver } from '@upstash/qstash';

  const receiver = new Receiver({
    currentSigningKey: process.env.QSTASH_CURRENT_SIGNING_KEY!,
    nextSigningKey: process.env.QSTASH_NEXT_SIGNING_KEY!
  });

  const isValid = await receiver.verify({
    signature: req.headers.get('Upstash-Signature')!,
    body: await req.text()
  });

  if (!isValid) return NextResponse.json({ error: 'Invalid signature' }, { status: 401 });
  ```
- **GOTCHA**: Must read request body before validation
- Test with `qstash` CLI tool

## Architecture Reference
- ARCHITECTURE.md Section 6: Endpoint Security
