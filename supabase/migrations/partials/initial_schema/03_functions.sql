-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Function to handle updated_at automatically
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to sync auth.users to public.users
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, email, created_at, updated_at)
    VALUES (NEW.id, NEW.email, NEW.created_at, NEW.updated_at);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to increment user's image usage count
CREATE OR REPLACE FUNCTION increment_user_image_count(p_user_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE public.users
    SET images_used_this_period = images_used_this_period + 1
    WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user has quota available
CREATE OR REPLACE FUNCTION check_user_quota(p_user_id UUID)
RETURNS TABLE(has_quota BOOLEAN, used INTEGER, limit INTEGER) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (st.images_per_period = -1 OR u.images_used_this_period < st.images_per_period) as has_quota,
        u.images_used_this_period as used,
        st.images_per_period as limit
    FROM public.users u
    JOIN public.subscription_tiers st ON u.subscription_tier = st.tier_name
    WHERE u.id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;