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