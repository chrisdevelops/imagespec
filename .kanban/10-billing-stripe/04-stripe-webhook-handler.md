# Stripe Webhook Handler

## Description
Implement webhook endpoint to handle Stripe events and sync subscription data.

## Dependencies
- [ ] 10-billing-stripe/01-stripe-configuration.md

## Acceptance Criteria
- [ ] POST /api/webhooks/stripe endpoint
- [ ] Signature validation
- [ ] Handles customer.subscription.created
- [ ] Handles customer.subscription.updated
- [ ] Handles customer.subscription.deleted
- [ ] Handles invoice.paid
- [ ] Handles invoice.payment_failed
- [ ] Idempotency (processed event tracking)
- [ ] Updates public.users
- [ ] Resets quota on renewal
- [ ] Logging to Sentry

## Technical Notes
- Validate signature:
  ```typescript
  const sig = req.headers.get('stripe-signature')!;
  const event = stripe.webhooks.constructEvent(
    await req.text(),
    sig,
    process.env.STRIPE_WEBHOOK_SECRET!
  );
  ```
- Handle events:
  - subscription.created/updated: sync subscription_tier, dates
  - invoice.paid: reset images_used_this_period
  - payment_failed: set status to past_due
- Store processed event IDs to prevent duplicates
- **GOTCHA**: Must return 200 even if internal error (after signature validation)
- Use service_role for DB updates

## Architecture Reference
- ARCHITECTURE.md Section 9: Webhook Handler
