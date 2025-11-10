-- ============================================================================
-- RLS POLICIES - SUBSCRIPTION TIERS
-- ============================================================================

-- All authenticated users can view subscription tiers
CREATE POLICY "Authenticated users can view subscription tiers" 
    ON public.subscription_tiers 
    FOR SELECT 
    USING (auth.role() = 'authenticated');

-- Note: No INSERT, UPDATE, or DELETE policies for users
-- Subscription tiers should only be managed by admins via the service role