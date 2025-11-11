# Core Tables Migration

## Description
Create all core database tables including subscription_tiers, users, collections, images, image_metadata, and ai_responses with proper relationships, constraints, and indexes.

## Dependencies
- [ ] 01-infrastructure-database/01-initial-database-setup.md

## Acceptance Criteria
- [ ] `subscription_tiers` table created with tier_name as PK
- [ ] `public.users` table created with FK to auth.users
- [ ] `collections` table created with user_id FK
- [ ] `images` table created with collection_id FK and status field
- [ ] `image_metadata` table created with UNIQUE image_id constraint
- [ ] `ai_responses` table created with encrypted response_payload field (BYTEA)
- [ ] All indexes created (user_period_end, collections_user_id, images_collection_id, images_status, image_metadata_image_id, ai_responses_image_idx)
- [ ] All foreign key constraints configured with proper ON DELETE CASCADE
- [ ] All CHECK constraints implemented (file_size, dimensions, tier_name pattern)
- [ ] Migration runs successfully: `supabase db reset`
- [ ] Schema matches ARCHITECTURE.md Section 3

## Technical Notes
- Create migration: `supabase migration create core_tables`
- Order matters: subscription_tiers MUST be created before users (FK dependency)
- Seed subscription_tiers data BEFORE adding FK constraint to users
- Use `gen_random_uuid()` for default UUIDs (requires pgcrypto)
- File in: `supabase/migrations/partials/initial_schema/01_tables.sql`
- images.status ENUM values: 'processing', 'completed', 'failed'
- images.file_size: max 10485760 bytes (10MB)
- image_metadata dimensions: max 8000px width/height
- ai_responses.response_payload: BYTEA for encrypted storage
- **GOTCHA**: Create subscription_tiers first, seed it, THEN add FK constraint to users.subscription_tier

## Architecture Reference
- Section 3.2: Core Tables Migration
- Section 3.3: ai_responses table
- ARCHITECTURE.md lines 7-98 (full schema)
