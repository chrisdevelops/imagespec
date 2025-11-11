# AI Responses Retention and Purge Job

## Description
Implement a scheduled job to purge ai_responses older than 90 days to manage storage costs and comply with data retention policies.

## Dependencies
- [ ] 01-infrastructure-database/02-core-tables-migration.md

## Acceptance Criteria
- [ ] Purge SQL script created: `DELETE FROM ai_responses WHERE received_at < NOW() - INTERVAL '90 days'`
- [ ] Scheduled function configured in Supabase (daily execution)
- [ ] OR cron job configured to run purge via API endpoint
- [ ] Purge logs execution results
- [ ] Dry-run tested to verify records selected
- [ ] Production purge scheduled but not run until MVP has data
- [ ] Documentation added for changing retention period

## Technical Notes
- Two options for scheduling:
  1. **Supabase Scheduled Function** (pg_cron): Create SQL function + cron job
  2. **External cron** (Vercel Cron or similar): Hit API endpoint that executes purge
- Purge SQL:
  ```sql
  DELETE FROM public.ai_responses
  WHERE received_at < NOW() - INTERVAL '90 days';
  ```
- For Supabase scheduled function:
  ```sql
  SELECT cron.schedule('purge-old-ai-responses', '0 2 * * *',
    'DELETE FROM public.ai_responses WHERE received_at < NOW() - INTERVAL ''90 days''');
  ```
- Consider archiving to S3 cold storage before deletion (future enhancement)
- Log number of rows deleted for monitoring
- **GOTCHA**: Test on staging with sample old data first
- **TODO**: Add monitoring alert if purge job fails

## Architecture Reference
- Section 3.7: Purge job (retention) example
- Section 13: Cost & optimization notes
- Section 18: Redaction & encryption (implementation notes)
