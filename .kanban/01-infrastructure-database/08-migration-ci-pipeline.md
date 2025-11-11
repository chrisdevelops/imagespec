# Migration CI/CD Pipeline

## Description
Set up automated migration deployment pipeline for staging and production environments using Supabase CLI in GitHub Actions or similar CI/CD.

## Dependencies
- [ ] 01-infrastructure-database/01-initial-database-setup.md
- [ ] 01-infrastructure-database/02-core-tables-migration.md

## Acceptance Criteria
- [ ] GitHub Actions workflow created (or similar CI/CD)
- [ ] Workflow runs on merge to `main` branch
- [ ] Migrations applied automatically to staging environment
- [ ] Production migrations require manual approval
- [ ] Service role key stored in CI secrets (never in code)
- [ ] Migration success/failure logged
- [ ] Rollback procedure documented
- [ ] Failed migrations halt deployment
- [ ] Workflow tested on staging

## Technical Notes
- Create `.github/workflows/deploy-migrations.yml`
- Install Supabase CLI in workflow: `npm install -g supabase`
- Link to project: `supabase link --project-ref ${{ secrets.SUPABASE_PROJECT_REF }}`
- Run migrations: `supabase db push`
- Store in secrets:
  - `SUPABASE_ACCESS_TOKEN` (for linking)
  - `SUPABASE_DB_PASSWORD` (service_role password)
  - `SUPABASE_PROJECT_REF` (staging and production IDs)
- Example workflow step:
  ```yaml
  - name: Run Supabase Migrations
    env:
      SUPABASE_ACCESS_TOKEN: ${{ secrets.SUPABASE_ACCESS_TOKEN }}
    run: |
      supabase link --project-ref ${{ secrets.SUPABASE_PROJECT_REF }}
      supabase db push
  ```
- Test locally: `supabase db reset` (applies all migrations)
- **GOTCHA**: Migrations are irreversible - test thoroughly in staging first
- **GOTCHA**: Some operations require service_role (auth trigger) - ensure sufficient permissions

## Architecture Reference
- Section 11: Deploying migrations
- Section 19: Migration & CI note
