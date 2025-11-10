-- ============================================================================
-- RLS POLICIES - USERS
-- ============================================================================

-- Users can view their own data
CREATE POLICY "Users can view own data" 
    ON public.users 
    FOR SELECT 
    USING (auth.uid() = id);

-- Note: No INSERT policy - users are created automatically via trigger when auth.users is created
-- Note: No UPDATE policy - user data should be updated via backend services or specific functions
-- Note: No DELETE policy - users are deleted via cascade when auth.users is deleted