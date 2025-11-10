-- ============================================================================
-- INITIAL SCHEMA MIGRATION
-- Created: 2024-01-01
-- Description: Core tables for users, collections, images, and metadata
-- ============================================================================

\ir partials/initial/01_tables.sql
\ir partials/initial/02_indexes.sql
\ir partials/initial/03_functions.sql
\ir partials/initial/04_triggers.sql
\ir partials/initial/05_rls_enable.sql
\ir partials/initial/06_rls_policies_users.sql
\ir partials/initial/07_rls_policies_collections.sql
\ir partials/initial/08_rls_policies_images.sql
\ir partials/initial/09_rls_policies_metadata.sql
\ir partials/initial/10_rls_policies_subscription_tiers.sql
\ir partials/initial/11_seed_data.sql