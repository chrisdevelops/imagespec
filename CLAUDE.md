# ImageSpec Development Guide (CLAUDE.md)

**AI-powered metadata for better web design**  
**Last Updated:** 2025-11-10

For detailed architecture, database schema, and API contracts, see `ARCHITECTURE.md`.

---

## Core Development Principles

### 1. Small Files, Single Responsibility
One file = one concern. Rather have 20 focused files than one 2000-line file.
```
src/lib/db/queries/images.ts    # Only image queries
src/lib/ai/providers/openai.ts  # Only OpenAI adapter
src/components/images/ImageCard.tsx
```

### 2. Descriptive, Self-Documenting Names
Names should clearly express intent. No cryptic abbreviations.
```typescript
// Good
async function getUserSubscriptionTierWithQuota(userId: string) { }
const remainingUploadSlotsForUser = 5;

// Bad
async function ur(uid: string) { }
const rem = 5;
```

### 3. DRY — Don't Repeat Yourself
Extract repeated patterns into reusable functions.
```typescript
// Abstract once, use everywhere
export function parseAiResponse(raw: string) { }

// Not: same logic duplicated in two API routes
```

### 4. ShadCN Components First
Always check ShadCN library before building custom components. They're production-tested and accessible.

### 5. Clarity Over Micro-Optimization
Write code that reads like English. Optimize only when there's a proven performance bottleneck.

### 6. Types in Separate Files
All TypeScript interfaces go in `src/lib/types/*.ts`. Never inline complex types.
```typescript
// src/lib/types/image.ts — all image types here
// src/components/images/ImageCard.tsx — import from types file
```

### 7. Comment Gotchas, TODOs, Context
Comment the WHY, not the WHAT. Flag important gotchas and TODOs.
```typescript
// GOTCHA: If success=false, must call decrement to rollback
// TODO: Add rate limiting
// NOTE: Requires service_role key; never expose to client
```

---

## File Organization

```
src/
  lib/
    types/          # All TypeScript interfaces (one domain per file)
    db/
      queries/      # Database queries (one table per file)
      rpc/          # RPC functions (one logical group per file)
      client.ts     # Supabase client setup
    ai/
      providers/    # OpenAI, Anthropic adapters + factory
      parser.ts     # Response parsing & validation
      redaction.ts  # PII redaction
    storage/        # S3, CloudFront operations
    auth/           # Authentication helpers
    hooks/          # React hooks (data fetching, state)
    utils/          # Utilities (errors, logging, formatting)
    env.ts          # Environment variable validation
  components/       # React components (organized by feature)
  app/api/          # Next.js API routes (kebab-case paths)
  migrations/       # Database migrations
```

**Naming:**
- Files/dirs: `kebab-case`
- Components: `PascalCase` (ImageCard.tsx)
- Functions: `camelCase` (generateS3Key)
- Constants: `UPPER_SNAKE_CASE` (MAX_UPLOAD_SIZE)
- Types: `PascalCase` (ImageMetadata)

---

## Database & API Patterns

### Supabase Setup
```typescript
// src/lib/db/client.ts
export function createSupabaseClient() { }         // Client (auth + RLS)
export function createSupabaseServiceClient() { }  // Server (service_role)
```

### Query Organization
- Each table gets its own file in `src/lib/db/queries/`
- Return typed responses
- Wrap errors clearly

### API Route Pattern
1. Validate request with Zod
2. Check auth/authorization
3. Call DB queries
4. Return: `{ data: T }` or `{ error: string }`
5. Handle errors with clear messages

See `ARCHITECTURE.md` Section 5 for complete endpoint contracts.

---

## Frontend Patterns

**Components:**
- Use ShadCN components
- Props as TypeScript interfaces
- Style with Tailwind utility classes
- Keep small and focused

**Data Fetching:**
- Store hooks in `src/lib/hooks/`
- Use `useQuery`/`useMutation` for HTTP
- Supabase Realtime for live updates

**State Management:**
- React hooks for simple state
- `useReducer` + Context for complex state
- No Redux unless absolutely necessary

---

## Image Processing Architecture

### High-Level Flow
```
1. User uploads → S3 (signed URL, direct)
2. Server creates images row + enqueues QStash
3. QStash → /api/jobs/process-image webhook
4. Processor:
   - Download from S3
   - Extract metadata (Sharp, node-vibrant)
   - Call AI provider (OpenAI/Anthropic)
   - Redact & encrypt AI response
   - Store in DB (encrypted ai_responses + image_metadata)
5. Frontend Realtime subscription → show metadata
```

### AI Adapter Pattern
**All in `src/lib/ai/`:**
- `providers/types.ts` — AiProvider interface
- `providers/openai.ts` — OpenAI implementation
- `providers/anthropic.ts` — Anthropic implementation
- `providers/factory.ts` — Select provider based on env var
- `parser.ts` — Parse any response into ImageMetadata
- `redaction.ts` — PII redaction before storage

Both adapters return the same `AiResponse` type for consistency.

### Quota Management
```typescript
// Check & atomically reserve slots (prevents race conditions)
const result = await checkAndReserveSlots(userId, count);
if (!result.success) {
  // Handle quota exceeded
  await decrementUserImageCount(userId, count); // rollback if needed
}
```

See `ARCHITECTURE.md` Section 3-6 for RPC details and database schema.

---

## Authentication & Security

### Server-Side Auth
```typescript
import { verifyAuth } from '@/lib/auth/server';

const { userId } = await verifyAuth();
if (!userId) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
```

### Key Rules
- **RLS enabled** on all tables
- **Policies check `auth.uid()`** against user_id
- **Service role sparingly** — server-only, never expose key to client
- **Validate at boundaries** — use Zod for API requests
- **Env vars** — validate with Zod in `src/lib/env.ts`

See `ARCHITECTURE.md` Section 10 for RLS policies.

---

## Common Tasks

**Add API Endpoint:**
1. Create `src/app/api/[route]/route.ts`
2. Define types in `src/lib/types/api.ts`
3. Validate request with Zod
4. Call DB queries from `src/lib/db/queries/`
5. Add error handling

**Create Component:**
1. Create `src/components/[section]/ComponentName.tsx`
2. Define props interface
3. Import ShadCN components
4. Style with Tailwind
5. Keep it small

**Write Database Query:**
1. Create/edit `src/lib/db/queries/[table].ts`
2. Use `createSupabaseClient()` (or service client on server only)
3. Wrap in try/catch with clear error messages
4. Return typed response

**Add New Type:**
1. Create/edit `src/lib/types/[domain].ts`
2. Export interface with descriptive naming
3. Add JSDoc if complex
4. Re-export from `src/lib/types/index.ts`

---

## Development Workflow

**Git:**
```bash
git checkout -b feature/short-description
git commit -m "feat: clear description"
git push origin feature/short-description
# Create PR, merge after approval
```

**Linting & Formatting:**
```bash
npx biome format --write .    # Format
npx biome lint --write .      # Lint & fix
npx tsc --noEmit              # Type check
```

**Local Setup:**
```bash
npm install
supabase start
supabase db start
npm run dev
```

---

## References

- **ARCHITECTURE.md** — Full architecture, database schema, API contracts, RPC functions, security, deployment
- **src/** — Code structure and current patterns
- **migrations/** — Database migration files
- **tsconfig.json** — TypeScript strict mode enabled
- **biome.json** — Linting and formatting rules

---

## Before Starting Work

- [ ] Understand the user story / task
- [ ] Check existing patterns in relevant `src/lib/` or `src/components/` directories
- [ ] Create types first in `src/lib/types/` (if needed)
- [ ] Keep files small (one concern per file)
- [ ] Use descriptive names
- [ ] Look for DRY opportunities
- [ ] Validate at API boundaries with Zod
- [ ] Add comments for gotchas/TODOs/context
- [ ] Reference ARCHITECTURE.md for details on larger features

---

## Key Reminders

✓ **Small files** — One responsibility each  
✓ **Descriptive names** — Self-documenting code  
✓ **DRY** — Reuse, don't duplicate  
✓ **ShadCN first** — Check library before custom components  
✓ **Clarity** — Make it readable, optimize only if needed  
✓ **Types isolated** — All types in `src/lib/types/*.ts`  
✓ **Comment gotchas** — Flag important context and TODOs  
✓ **Validate input** — Use Zod at API boundaries  
✓ **Service role safe** — Keep key on server, never expose to client  
✓ **Structured logging** — Use `logStructured()` for debugging