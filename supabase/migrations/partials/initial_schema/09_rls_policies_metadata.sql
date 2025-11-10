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