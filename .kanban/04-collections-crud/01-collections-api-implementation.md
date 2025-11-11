# Collections API Implementation

## Description
Implement all collections API endpoints for CRUD operations with proper authentication, validation, and RLS enforcement.

## Dependencies
- [ ] 01-infrastructure-database/04-rls-setup.md
- [ ] 02-authentication/01-supabase-auth-client-setup.md

## Acceptance Criteria
- [ ] GET /api/collections - List user's collections
- [ ] POST /api/collections - Create new collection
- [ ] GET /api/collections/[id] - Get collection details
- [ ] PATCH /api/collections/[id] - Update collection
- [ ] DELETE /api/collections/[id] - Delete collection
- [ ] All endpoints validate auth.uid()
- [ ] Request/response types defined with Zod
- [ ] Error handling with proper HTTP status codes
- [ ] Pagination implemented for list endpoint
- [ ] Sorting and filtering options
- [ ] All endpoints tested

## Technical Notes
- Create API routes in `src/app/api/collections/`
- List collections:
  ```typescript
  export async function GET(request: Request) {
    const supabase = await createClient();
    const { data: { user } } = await supabase.auth.getUser();
    if (!user) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

    const { data, error } = await supabase
      .from('collections')
      .select('*')
      .order('created_at', { ascending: false });

    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json({ data });
  }
  ```
- Create collection with Zod validation:
  ```typescript
  const createCollectionSchema = z.object({
    name: z.string().min(1).max(100),
    description: z.string().max(500).optional()
  });
  ```
- RLS automatically enforces user ownership
- **GOTCHA**: Use server client (not browser client) in API routes
- **TODO**: Add pagination with limit/offset query params

## Architecture Reference
- ARCHITECTURE.md Section 5: Collections API Endpoints
- CLAUDE.md: API Route Pattern
