# Images API Implementation

## Description
Implement all images API endpoints for upload, retrieval, update, and deletion with proper RLS and quota checking.

## Dependencies
- [ ] 01-infrastructure-database/04-rls-setup.md
- [ ] 04-collections-crud/01-collections-api-implementation.md

## Acceptance Criteria
- [ ] POST /api/images/preupload - Request signed upload URLs
- [ ] POST /api/images/complete - Finalize upload and enqueue processing
- [ ] GET /api/images/[id] - Get image with metadata
- [ ] PATCH /api/images/[id] - Update metadata
- [ ] DELETE /api/images/[id] - Delete image
- [ ] POST /api/images/[id]/regenerate - Regenerate metadata
- [ ] All endpoints validate ownership via RLS
- [ ] File type and size validation
- [ ] Quota checking before upload
- [ ] Proper error handling

## Technical Notes
- Create API routes in `src/app/api/images/`
- Preupload flow:
  1. Validate file metadata
  2. Check quota via check_and_reserve_slots()
  3. Generate S3 signed URL
  4. Return uploadUrl + imageId
- Complete flow:
  1. Verify S3 object exists
  2. Create images DB row
  3. Enqueue QStash job
  4. Return imageId and status
- Use Zod for request validation
- **GOTCHA**: Must check quota BEFORE generating signed URLs
- **GOTCHA**: RLS policies enforce ownership automatically

## Architecture Reference
- ARCHITECTURE.md Section 5: Images API Endpoints
- ARCHITECTURE.md: Upload flow details
