# Stripe Configuration

## Description
Set up Stripe account, products, prices, and webhook endpoints for billing integration.

## Dependencies
- None (infrastructure)

## Acceptance Criteria
- [ ] Stripe account created (test + live)
- [ ] Products created (Free, Pro, Enterprise)
- [ ] Prices created for each product
- [ ] Price IDs documented
- [ ] Webhook endpoint configured
- [ ] Webhook signing secret obtained
- [ ] API keys stored securely
- [ ] Test mode verified working

## Technical Notes
- Create products in Stripe Dashboard
- Create recurring prices (monthly)
- Pro: $29.99/month
- Configure webhook URL: `https://yourdomain.com/api/webhooks/stripe`
- Store in .env:
  ```
  STRIPE_SECRET_KEY=sk_test_xxx (or sk_live_xxx)
  STRIPE_PUBLISHABLE_KEY=pk_test_xxx
  STRIPE_WEBHOOK_SECRET=whsec_xxx
  STRIPE_PRICE_ID_PRO=price_xxx
  STRIPE_PRICE_ID_ENTERPRISE=price_xxx
  ```
- Map price IDs to tier names
- **GOTCHA**: Use test keys for development
- **GOTCHA**: Different webhook secrets for test/live

## Architecture Reference
- ARCHITECTURE.md Section 9: Stripe Setup
