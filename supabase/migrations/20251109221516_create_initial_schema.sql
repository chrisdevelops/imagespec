CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================================================
-- TABLES
-- ============================================================================

-- Subscription tiers configuration table (CREATE FIRST)
CREATE TABLE public.subscription_tiers (
    tier_name TEXT PRIMARY KEY CHECK (tier_name ~ '^[a-z_]+$'),  -- More flexible
    display_name TEXT NOT NULL,
    images_per_period INTEGER NOT NULL CHECK (images_per_period = -1 OR images_per_period > 0),
    price_monthly INTEGER CHECK (price_monthly >= 0),
    features JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Users table (synced with auth.users)
CREATE TABLE public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    stripe_customer_id TEXT UNIQUE,
    stripe_subscription_id TEXT UNIQUE,
    subscription_tier TEXT NOT NULL DEFAULT 'free',  -- Remove CHECK for now
    subscription_status TEXT,
    current_period_start TIMESTAMPTZ,
    current_period_end TIMESTAMPTZ,
    images_used_this_period INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Collections table
CREATE TABLE public.collections (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Images table
CREATE TABLE public.images (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    original_name TEXT NOT NULL,
    s3_key TEXT UNIQUE NOT NULL,
    cdn_url TEXT NOT NULL,
    file_size INTEGER NOT NULL CHECK (file_size > 0 AND file_size <= 10485760),
    mime_type TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'processing',
    error_message TEXT,
    collection_id UUID NOT NULL REFERENCES public.collections(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Image metadata table
CREATE TABLE public.image_metadata (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    image_id UUID UNIQUE NOT NULL REFERENCES public.images(id) ON DELETE CASCADE,
    description TEXT NOT NULL,
    alt_text TEXT NOT NULL,
    content_keywords TEXT[] NOT NULL,
    dominant_colors JSONB NOT NULL,
    palette_mood TEXT NOT NULL,
    overall_tone TEXT NOT NULL,
    width INTEGER NOT NULL CHECK (width > 0 AND width <= 8000),
    height INTEGER NOT NULL CHECK (height > 0 AND height <= 8000),
    aspect_ratio TEXT NOT NULL,
    orientation TEXT NOT NULL,
    style_tags TEXT[] NOT NULL,
    mood TEXT[] NOT NULL,
    visual_weight TEXT NOT NULL,
    formality_level TEXT NOT NULL,
    focal_point TEXT NOT NULL,
    subject_type TEXT NOT NULL,
    background_complexity TEXT NOT NULL,
    negative_space TEXT NOT NULL,
    text_overlay_safe BOOLEAN NOT NULL,
    safe_text_zones TEXT[] NOT NULL,
    suggested_use_cases TEXT[] NOT NULL,
    text_content TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================================
-- SEED DATA (MOVED UP - BEFORE FOREIGN KEY)
-- ============================================================================

-- Seed subscription tiers
-- TODO: Finalize pricing and limits before launch
INSERT INTO public.subscription_tiers (tier_name, display_name, images_per_period, price_monthly, features) VALUES
    ('free', 'Free', 100, 0, '{"support": "community", "api_access": false}'),
    ('pro', 'Pro', 1000, 2999, '{"support": "email", "api_access": true, "priority_processing": true}'),
    ('enterprise', 'Enterprise', -1, NULL, '{"support": "dedicated", "api_access": true, "priority_processing": true, "custom_integrations": true}');


-- ============================================================================
-- FOREIGN KEY CONSTRAINTS (AFTER SEED DATA)
-- ============================================================================

-- Add foreign key constraint to users table for subscription tier
ALTER TABLE public.users
    ADD CONSTRAINT users_subscription_tier_fkey 
    FOREIGN KEY (subscription_tier) 
    REFERENCES public.subscription_tiers(tier_name);


-- ============================================================================
-- INDEXES
-- ============================================================================

CREATE INDEX users_period_end_idx ON public.users(current_period_end);
CREATE INDEX collections_user_id_idx ON public.collections(user_id);
CREATE INDEX images_collection_id_idx ON public.images(collection_id);
CREATE INDEX images_status_idx ON public.images(status);
CREATE INDEX image_metadata_image_id_idx ON public.image_metadata(image_id);


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
RETURNS TABLE(has_quota BOOLEAN, used INTEGER, quota_limit INTEGER) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (st.images_per_period = -1 OR u.images_used_this_period < st.images_per_period) as has_quota,
        u.images_used_this_period as used,
        st.images_per_period as quota_limit
    FROM public.users u
    JOIN public.subscription_tiers st ON u.subscription_tier = st.tier_name
    WHERE u.id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Triggers for updated_at columns
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON public.users 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_collections_updated_at 
    BEFORE UPDATE ON public.collections 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_images_updated_at 
    BEFORE UPDATE ON public.images 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_image_metadata_updated_at 
    BEFORE UPDATE ON public.image_metadata 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger to sync auth.users to public.users on signup
CREATE TRIGGER on_auth_user_created 
    AFTER INSERT ON auth.users 
    FOR EACH ROW 
    EXECUTE FUNCTION public.handle_new_user();


-- ============================================================================
-- ENABLE ROW LEVEL SECURITY
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.collections ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.image_metadata ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_tiers ENABLE ROW LEVEL SECURITY;


-- ============================================================================
-- RLS POLICIES - USERS
-- ============================================================================

-- Users can view their own data
CREATE POLICY "Users can view own data" 
    ON public.users 
    FOR SELECT 
    USING (auth.uid() = id);


-- ============================================================================
-- RLS POLICIES - COLLECTIONS
-- ============================================================================

-- Users can view their own collections
CREATE POLICY "Users can view own collections" 
    ON public.collections 
    FOR SELECT 
    USING (auth.uid() = user_id);

-- Users can create their own collections
CREATE POLICY "Users can create own collections" 
    ON public.collections 
    FOR INSERT 
    WITH CHECK (auth.uid() = user_id);

-- Users can update their own collections
CREATE POLICY "Users can update own collections" 
    ON public.collections 
    FOR UPDATE 
    USING (auth.uid() = user_id);

-- Users can delete their own collections
CREATE POLICY "Users can delete own collections" 
    ON public.collections 
    FOR DELETE 
    USING (auth.uid() = user_id);


-- ============================================================================
-- RLS POLICIES - IMAGES
-- ============================================================================

-- Users can view their own images
CREATE POLICY "Users can view own images" 
    ON public.images 
    FOR SELECT 
    USING (
        auth.uid() IN (
            SELECT user_id
            FROM public.collections
            WHERE id = images.collection_id
        )
    );

-- Users can create images in their own collections
CREATE POLICY "Users can create own images" 
    ON public.images 
    FOR INSERT 
    WITH CHECK (
        auth.uid() IN (
            SELECT user_id
            FROM public.collections
            WHERE id = images.collection_id
        )
    );

-- Users can update their own images
CREATE POLICY "Users can update own images" 
    ON public.images 
    FOR UPDATE 
    USING (
        auth.uid() IN (
            SELECT user_id
            FROM public.collections
            WHERE id = images.collection_id
        )
    );

-- Users can delete their own images
CREATE POLICY "Users can delete own images" 
    ON public.images 
    FOR DELETE 
    USING (
        auth.uid() IN (
            SELECT user_id
            FROM public.collections
            WHERE id = images.collection_id
        )
    );


-- ============================================================================
-- RLS POLICIES - IMAGE METADATA
-- ============================================================================

-- Users can view metadata for their own images
CREATE POLICY "Users can view own image metadata" 
    ON public.image_metadata 
    FOR SELECT 
    USING (
        auth.uid() IN (
            SELECT c.user_id
            FROM public.images i
            JOIN public.collections c ON i.collection_id = c.id
            WHERE i.id = image_metadata.image_id
        )
    );

-- Users can create metadata for their own images
CREATE POLICY "Users can create own image metadata" 
    ON public.image_metadata 
    FOR INSERT 
    WITH CHECK (
        auth.uid() IN (
            SELECT c.user_id
            FROM public.images i
            JOIN public.collections c ON i.collection_id = c.id
            WHERE i.id = image_metadata.image_id
        )
    );

-- Users can update metadata for their own images
CREATE POLICY "Users can update own image metadata" 
    ON public.image_metadata 
    FOR UPDATE 
    USING (
        auth.uid() IN (
            SELECT c.user_id
            FROM public.images i
            JOIN public.collections c ON i.collection_id = c.id
            WHERE i.id = image_metadata.image_id
        )
    );

-- Users can delete metadata for their own images
CREATE POLICY "Users can delete own image metadata" 
    ON public.image_metadata 
    FOR DELETE 
    USING (
        auth.uid() IN (
            SELECT c.user_id
            FROM public.images i
            JOIN public.collections c ON i.collection_id = c.id
            WHERE i.id = image_metadata.image_id
        )
    );


-- ============================================================================
-- RLS POLICIES - SUBSCRIPTION TIERS
-- ============================================================================

-- All authenticated users can view subscription tiers
CREATE POLICY "Authenticated users can view subscription tiers" 
    ON public.subscription_tiers 
    FOR SELECT 
    USING (auth.role() = 'authenticated');