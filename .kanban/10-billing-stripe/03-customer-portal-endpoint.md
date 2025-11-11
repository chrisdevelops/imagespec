# Customer Portal Endpoint

## Description
Implement endpoint to create Stripe Customer Portal sessions for self-service billing.

## Dependencies
- [ ] 10-billing-stripe/01-stripe-configuration.md

## Acceptance Criteria
- [ ] POST /api/billing/create-portal endpoint
- [ ] Retrieves customer ID from user
- [ ] Creates portal session
- [ ] Returns portal URL
- [ ] Proper auth required
- [ ] Error handling

## Technical Notes
- Create: `src/app/api/billing/create-portal/route.ts`
  ```typescript
  const session = await stripe.billingPortal.sessions.create({
    customer: user.stripe_customer_id,
    return_url: `${process.env.APP_URL}/account`
  });
  return NextResponse.json({ url: session.url });
  ```
- Portal allows users to:
  - Update payment method
  - Cancel subscription
  - View invoices
- **GOTCHA**: User must have stripe_customer_id

## Architecture Reference
- ARCHITECTURE.md Section 9: Customer Portal
