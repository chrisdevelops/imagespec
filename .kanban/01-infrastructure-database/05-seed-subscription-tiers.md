# Seed Subscription Tiers

## Description
Populate the subscription_tiers table with initial tier data (free, pro, enterprise) including pricing, quota limits, and feature flags.

## Dependencies
- [ ] 01-infrastructure-database/02-core-tables-migration.md

## Acceptance Criteria
- [ ] Free tier seeded: 100 images/period, $0/month, max_bulk_upload: 1
- [ ] Pro tier seeded: 1000 images/period, $29.99/month, max_bulk_upload: 20
- [ ] Enterprise tier seeded: unlimited (-1), custom pricing, unlimited bulk
- [ ] Features JSONB includes: support level, api_access, priority_processing
- [ ] Pro features JSONB: `{"max_bulk_upload": 20, "api_access": true, "priority_processing": true, "support": "email"}`
- [ ] Enterprise features JSONB: `{"api_access": true, "priority_processing": true, "custom_integrations": true, "support": "dedicated"}`
- [ ] Seed data runs in migration
- [ ] Query subscription_tiers to verify data

## Technical Notes
- File in: `supabase/migrations/partials/initial_schema/11_seed_data.sql`
- Insert statement:
  ```sql
  INSERT INTO public.subscription_tiers (tier_name, display_name, images_per_period, price_monthly, features) VALUES
    ('free', 'Free', 100, 0, '{"support": "community", "api_access": false, "max_bulk_upload": 1}'),
    ('pro', 'Pro', 1000, 2999, '{"support": "email", "api_access": true, "priority_processing": true, "max_bulk_upload": 20}'),
    ('enterprise', 'Enterprise', -1, NULL, '{"support": "dedicated", "api_access": true, "priority_processing": true, "custom_integrations": true}');
  ```
- price_monthly in cents: $29.99 = 2999
- images_per_period = -1 means unlimited
- **TODO**: Finalize pricing before production launch
- **GOTCHA**: Seed BEFORE adding FK constraint from users.subscription_tier
- Access features: `SELECT features->>'max_bulk_upload' FROM subscription_tiers WHERE tier_name = 'pro';`

## Architecture Reference
- Section 4: Data model notes & rationale
- ARCHITECTURE.md lines 92-97 (seed data SQL)
- Section 17: Where to change bulk upload & related configs
