# Quota Checking API

## Description
Implement API endpoint to check user's current quota and remaining uploads.

## Dependencies
- [ ] 06-quota-management/01-quota-rpcs-implementation.md

## Acceptance Criteria
- [ ] GET /api/usage endpoint implemented
- [ ] Returns used, quota_limit, remaining
- [ ] Returns subscription tier info
- [ ] Returns features (max_bulk_upload, etc.)
- [ ] Proper auth required
- [ ] Error handling

## Technical Notes
- Create route: `src/app/api/usage/route.ts`
- Call get_user_quota() RPC
- Join subscription_tiers for features
- Return format:
  ```json
  {
    "used": 45,
    "quota_limit": 100,
    "remaining": 55,
    "tier": "free",
    "features": {
      "max_bulk_upload": 1
    }
  }
  ```

## Architecture Reference
- ARCHITECTURE.md: Quota System Implementation
