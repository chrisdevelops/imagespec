# Checkout Session Endpoint

## Description
Implement API endpoint to create Stripe Checkout sessions for subscriptions.

## Dependencies
- [ ] 10-billing-stripe/01-stripe-configuration.md

## Acceptance Criteria
- [ ] POST /api/billing/create-checkout endpoint
- [ ] Accepts tier selection
- [ ] Creates/retrieves Stripe customer
- [ ] Creates Checkout Session
- [ ] Returns session URL
- [ ] Success/cancel URLs configured
- [ ] Error handling
- [ ] Proper auth required

## Technical Notes
- Install: `npm install stripe`
- Create: `src/app/api/billing/create-checkout/route.ts`
  ```typescript
  import Stripe from 'stripe';
  const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!);

  export async function POST(req: Request) {
    const { tier } = await req.json();
    const priceId = getPriceIdForTier(tier);

    const session = await stripe.checkout.sessions.create({
      mode: 'subscription',
      payment_method_types: ['card'],
      line_items: [{ price: priceId, quantity: 1 }],
      success_url: `${process.env.APP_URL}/billing/success`,
      cancel_url: `${process.env.APP_URL}/billing/cancel`
    });

    return NextResponse.json({ url: session.url });
  }
  ```
- **GOTCHA**: Create customer in Stripe if doesn't exist
- Store stripe_customer_id in public.users

## Architecture Reference
- ARCHITECTURE.md Section 9: Checkout Flow
