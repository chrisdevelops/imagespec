-- ============================================================================
-- TABLES
-- ============================================================================

-- Users table (synced with auth.users)
CREATE TABLE public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    stripe_customer_id TEXT UNIQUE,
    stripe_subscription_id TEXT UNIQUE,
    subscription_tier TEXT NOT NULL DEFAULT 'free' CHECK (subscription_tier IN ('free', 'pro', 'enterprise')),
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

-- Subscription tiers configuration table
CREATE TABLE public.subscription_tiers (
    tier_name TEXT PRIMARY KEY CHECK (tier_name IN ('free', 'pro', 'enterprise')),
    display_name TEXT NOT NULL,
    images_per_period INTEGER NOT NULL CHECK (images_per_period = -1 OR images_per_period > 0),
    price_monthly INTEGER CHECK (price_monthly >= 0),
    features JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add foreign key constraint to users table for subscription tier
ALTER TABLE public.users
    ADD CONSTRAINT users_subscription_tier_fkey 
    FOREIGN KEY (subscription_tier) 
    REFERENCES public.subscription_tiers(tier_name);