-- ============================================================================
-- SEED DATA
-- ============================================================================

-- Seed subscription tiers
-- TODO: Finalize pricing and limits before launch
INSERT INTO public.subscription_tiers (tier_name, display_name, images_per_period, price_monthly, features) VALUES
    ('free', 'Free', 100, 0, '{"support": "community", "api_access": false}'),
    ('pro', 'Pro', 1000, 2999, '{"support": "email", "api_access": true, "priority_processing": true}'),
    ('enterprise', 'Enterprise', -1, NULL, '{"support": "dedicated", "api_access": true, "priority_processing": true, "custom_integrations": true}');