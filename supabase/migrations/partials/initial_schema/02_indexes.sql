-- ============================================================================
-- INDEXES
-- ============================================================================

CREATE INDEX users_period_end_idx ON public.users(current_period_end);
CREATE INDEX collections_user_id_idx ON public.collections(user_id);
CREATE INDEX images_collection_id_idx ON public.images(collection_id);
CREATE INDEX images_status_idx ON public.images(status);
CREATE INDEX image_metadata_image_id_idx ON public.image_metadata(image_id);