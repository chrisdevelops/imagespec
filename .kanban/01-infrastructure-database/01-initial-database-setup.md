# Initial Database Setup

## Description
Set up the foundational database infrastructure including Supabase projects for development, staging, and production environments, and enable the pgcrypto extension required for UUID generation.

## Dependencies
- None (first task)

## Acceptance Criteria
- [ ] Supabase development project created and accessible
- [ ] Supabase staging project created (optional for MVP)
- [ ] Supabase production project created
- [ ] pgcrypto extension enabled in all environments
- [ ] Database connection strings stored securely in environment variables
- [ ] Service role keys stored securely (never committed to git)
- [ ] Anon keys configured for client-side usage
- [ ] Migration tooling configured (supabase CLI)
- [ ] `.env.local` and `.env.production` configured with correct values

## Technical Notes
- Install Supabase CLI: `npm install supabase --save-dev`
- Initialize Supabase: `supabase init` (already done in this project)
- Link to remote project: `supabase link --project-ref <project-id>`
- Enable pgcrypto in first migration: `CREATE EXTENSION IF NOT EXISTS "pgcrypto";`
- Store in `.env.local`:
  ```bash
  NEXT_PUBLIC_SUPABASE_URL=<your-project-url>
  NEXT_PUBLIC_SUPABASE_ANON_KEY=<anon-key>
  SUPABASE_SERVICE_ROLE_KEY=<service-role-key>
  ```
- **GOTCHA**: Service role key bypasses RLS - never expose to client
- **GOTCHA**: Different projects for dev/staging/prod prevent data mixing

## Architecture Reference
- Section 3.1: Required top-of-migration
- Section 11: Environments & deployment
