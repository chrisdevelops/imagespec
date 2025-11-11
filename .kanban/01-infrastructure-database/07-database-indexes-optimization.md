# Database Indexes and Optimization

## Description
Create all necessary indexes for optimal query performance and verify query plans for common operations.

## Dependencies
- [ ] 01-infrastructure-database/02-core-tables-migration.md

## Acceptance Criteria
- [ ] Index on users(current_period_end) for subscription renewal queries
- [ ] Index on collections(user_id) for user's collections lookup
- [ ] Index on images(collection_id) for collection's images lookup
- [ ] Index on images(status) for processing queue queries
- [ ] Index on image_metadata(image_id) for metadata joins
- [ ] Index on ai_responses(image_id) for AI response lookups
- [ ] Query plans analyzed for RLS policy joins
- [ ] All common queries use indexes (no sequential scans on large tables)
- [ ] Composite indexes added if needed for multi-column queries

## Technical Notes
- File in: `supabase/migrations/partials/initial_schema/02_indexes.sql`
- Create index syntax:
  ```sql
  CREATE INDEX users_period_end_idx ON public.users(current_period_end);
  CREATE INDEX collections_user_id_idx ON public.collections(user_id);
  CREATE INDEX images_collection_id_idx ON public.images(collection_id);
  CREATE INDEX images_status_idx ON public.images(status);
  CREATE INDEX image_metadata_image_id_idx ON public.image_metadata(image_id);
  CREATE INDEX ai_responses_image_idx ON public.ai_responses(image_id);
  ```
- Analyze query plans: `EXPLAIN ANALYZE SELECT ...`
- Check RLS policy performance with typical user queries
- Consider partial index on images(status) WHERE status = 'processing' if needed
- Monitor index usage: `SELECT * FROM pg_stat_user_indexes;`
- **GOTCHA**: Indexes speed up reads but slow down writes - balance needed
- **TODO**: Monitor query performance in production, add indexes as needed

## Architecture Reference
- ARCHITECTURE.md lines 113-119 (indexes section)
- Section 11: Observability & analytics (database monitoring)
