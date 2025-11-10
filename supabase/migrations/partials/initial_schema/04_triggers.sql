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