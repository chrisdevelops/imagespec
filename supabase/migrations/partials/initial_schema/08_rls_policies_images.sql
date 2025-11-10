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