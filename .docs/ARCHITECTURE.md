# ImageSpec — Architecture Document v2

**AI-powered metadata for better web design**
**Version:** 2.0 — *Built from v1 + confirmed decisions*
**Last updated:** 2025-11-10

This document replaces and extends your original architecture doc (v1). It incorporates your confirmed choices (Supabase Auth, Supabase Postgres without Prisma, S3 + CloudFront, QStash + Next.js API route processors for MVP, Stripe Checkout redirect, multi-provider AI adapter, Sentry & Plausible, Pro bulk limit = 20 by default, `ai_responses` retention & redaction strategy, atomic DB reserve RPC). It is written to be actionable: it contains architecture, behavioral rules, SQL snippets, API contracts, deployment/staging guidance, security considerations, and a prioritized implementation breakdown that can be split into user stories.

---

## Executive summary (TL;DR)

* **Auth & DB**: Supabase Auth as source of truth. `public.users` mirrored via `auth.users` trigger. Row-Level Security enabled. Server tasks use the Supabase `service_role`.
* **Storage & CDN**: S3 for object storage, CloudFront for CDN. Signed PUTs for uploads (direct-to-S3).
* **Processing**: Frontend uploads → Next.js API creates DB row + enqueues QStash job → QStash calls Next.js webhook `/api/jobs/process-image` → processor downloads image, runs deterministic analysis (Sharp, node-vibrant), calls AI provider via adapter, writes `image_metadata` + `ai_responses`, then calls DB RPC to increment usage on success.
* **Quota model**: App calls an atomic DB RPC `check_and_reserve_slots` to reserve slots for bulk upload; the processor will rollback (decrement) on failure. Pro default bulk limit = **20** (configurable via `subscription_tiers.features`).
* **AI**: Use deterministic algorithms for dimensions/colors; use AI vision (either OpenAI/Anthropic or pluggable providers) for semantic metadata. Store raw AI responses in `ai_responses` with 90-day retention; apply regex redaction + encryption before persisting.
* **Billing**: Stripe Checkout + Customer Portal. Webhooks sync `stripe_*` fields to `public.users`.
* **MVP hosting**: Vercel for frontend + Next.js API routes; QStash + Next.js webhook processors for MVP. Documented migration path to a dedicated worker (Render, Railway, Cloud Run) if needed.
* **Monitoring**: Sentry (error & perf) + Plausible (website analytics).

---

# 1. Goals & scope for v2

1. Be explicit about the technical requirements so the product can be broken into development tasks / user stories.
2. Provide DB-level primitives (RPCs) for safe concurrency and quota enforcement.
3. Ensure privacy & traceability for AI outputs with a practical PII-mitigation approach.
4. Keep the MVP lightweight (use QStash + Next.js routes) and make scaling predictable.

---

# 2. High-level architecture (revised)

```
User Browser (Next.js App)
  └─> Signed PUT to S3 (via /api/upload-url) or upload via API
       └─> POST /api/images -> create images row (status=processing)
             └─> call RPC check_and_reserve_slots(user, count)  ← atomic reservation
             └─> enqueue QStash job { image_id, attempt:0 }
QStash
  └─> POST /api/jobs/process-image (QStash webhook -> Next.js API Route)
       └─> Processor (Next.js route executes processing)
            ├─> Download from S3
            ├─> Deterministic analysis (Sharp, node-vibrant)
            ├─> Call AI adapter(s) for semantic metadata
            ├─> Redact & encrypt AI response; INSERT into ai_responses
            ├─> Upsert image_metadata
            ├─> Update images.status → completed / failed
            └─> On success: call RPC increment_user_image_count(user, count) or rely on reserve semantics
Stripe Webhooks
  └─> POST /api/webhooks/stripe -> update public.users subscription fields, reset usage on renewal
Supabase (Postgres)
  ├─> public.users, collections, images, image_metadata, ai_responses, subscription_tiers
  └─> RLS policies enforce row access
S3 + CloudFront
  └─> store images, serve publicly via CDN (or signed CDN URLs)
Sentry + Plausible
  └─> monitoring & analytics
```

---

# 3. Database: schema, RPCs, triggers (concrete)

Use the SQL below as migrations for Supabase. These include the recommended additions: `pgcrypto` extension, idempotent user sync trigger, `ai_responses` table, `check_and_reserve_slots`, `decrement_user_image_count`, `decrement` for rollbacks, and a daily purge.

> **Important**: run migrations using the Supabase service role / DB owner (needed for `auth` schema trigger and SECURITY DEFINER functions).

### 3.1 Required top-of-migration

```sql
-- ensure pgcrypto (for gen_random_uuid)
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
```

### 3.2 Idempotent user sync function & trigger (auth.users → public.users)

```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, created_at, updated_at)
  VALUES (NEW.id, NEW.email, COALESCE(NEW.created_at, NOW()), COALESCE(NEW.updated_at, NOW()))
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
```

> Note: execute as DB owner / service_role. `auth.users` contains `created_at` — `updated_at` may not exist; function above is defensive.

### 3.3 `ai_responses` table (store raw AI outputs securely)

```sql
CREATE TABLE public.ai_responses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  image_id UUID REFERENCES public.images(id) ON DELETE CASCADE,
  provider TEXT NOT NULL,
  model TEXT,
  request_payload JSONB,
  response_payload BYTEA, -- store encrypted bytes (ciphertext)
  redacted_payload JSONB, -- optional sanitized summary
  received_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX ai_responses_image_idx ON public.ai_responses(image_id);
```

> We store `response_payload` as encrypted binary (app-level encryption recommended) and optionally `redacted_payload` as JSON summary.

### 3.4 Atomic reserve RPC (check + reserve)

```sql
CREATE OR REPLACE FUNCTION public.check_and_reserve_slots(
  p_user_id UUID,
  p_count INT DEFAULT 1
)
RETURNS TABLE(
  success BOOLEAN,
  used INTEGER,
  quota_limit INTEGER,
  remaining INTEGER
) AS $$
BEGIN
  RETURN QUERY
  WITH tier AS (
    SELECT st.images_per_period
    FROM public.users u
    JOIN public.subscription_tiers st ON u.subscription_tier = st.tier_name
    WHERE u.id = p_user_id
    FOR UPDATE
  ), updated AS (
    UPDATE public.users
    SET images_used_this_period = images_used_this_period + p_count
    WHERE id = p_user_id
    RETURNING images_used_this_period
  )
  SELECT
    (tier.images_per_period = -1 OR updated.images_used_this_period <= tier.images_per_period) AS success,
    updated.images_used_this_period AS used,
    tier.images_per_period AS quota_limit,
    CASE WHEN tier.images_per_period = -1 THEN -1
         ELSE GREATEST(tier.images_per_period - updated.images_used_this_period, 0)
    END AS remaining
  FROM updated, tier;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Behavior**: serialized `FOR UPDATE` prevents race conditions. If `success=false`, app can `decrement_user_image_count()` to rollback or notify user.

### 3.5 Decrement (rollback) RPC

```sql
CREATE OR REPLACE FUNCTION public.decrement_user_image_count(p_user_id UUID, p_count INT DEFAULT 1)
RETURNS void AS $$
BEGIN
  UPDATE public.users
  SET images_used_this_period = GREATEST(images_used_this_period - p_count, 0)
  WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### 3.6 Optional convenience: simple quota read (no reservation)

```sql
CREATE OR REPLACE FUNCTION public.get_user_quota(p_user_id UUID)
RETURNS TABLE(used INT, quota_limit INT, remaining INT) AS $$
BEGIN
  RETURN QUERY
  SELECT u.images_used_this_period, st.images_per_period,
    CASE WHEN st.images_per_period = -1 THEN -1 ELSE GREATEST(st.images_per_period - u.images_used_this_period, 0) END
  FROM public.users u JOIN public.subscription_tiers st ON u.subscription_tier = st.tier_name
  WHERE u.id = p_user_id;
END;
$$ LANGUAGE plpgsql STABLE;
```

### 3.7 Purge job (retention) example (run daily via scheduled function)

```sql
-- purge ai_responses older than 90 days
DELETE FROM public.ai_responses
WHERE received_at < NOW() - INTERVAL '90 days';
```

> Implement as Supabase Scheduled Function or external cron. Consider archiving to cold storage if desired.

### 3.8 Triggers for `updated_at` (already in v1); keep them.

> Ensure functions are created with appropriate owners.

---

# 4. Data model notes & rationale

* `image_metadata` remains one-to-one with `images` (unique `image_id`). If you later want versioning, add `image_metadata_history` or remove UNIQUE and add `version` field.
* `ai_responses` stores raw model output detached from user-identifying fields; store only `image_id` as join key. Encrypt raw response blob. Store a small redacted summary in `redacted_payload` if useful.
* `subscription_tiers.features` (JSONB) will store `max_bulk_upload`, `priority_processing`, `api_access` so limits and behaviors are configurable without migration.

Example `features` value:

```json
{ "max_bulk_upload": 20, "api_access": true, "priority_processing": true }
```

---

# 5. API surface (concrete endpoints & contracts)

These are the endpoints (v1 updated). Include exact semantics for implementation.

### Auth (Supabase Auth client-library used)

* Client uses Supabase JS for sign-up, sign-in, magic links, social OAuth. No custom password storage.

### Images & Collections

* `GET /api/collections` — auth required; returns collections for current user.

* `POST /api/collections` — body `{ name, description }` — create `collections` row with `user_id = auth.uid()`.

* `GET /api/collections/[id]` — details, images, metadata.

* `GET /api/collections/[id]/export` — returns formatted JSON (streaming if large).

* `POST /api/images` — *Upload flow (recommended)*:

  * **Step A**: Client requests signed upload URL for each file:

    * `POST /api/images/preupload` body `{ filename, contentType, size, collectionId }`:

      * Server calls `get_user_quota` or checks `check_and_reserve_slots` (if batch). If OK, server returns `{ uploadUrl, s3Key, imageId }`.
  * **Step B**: Client does PUT to `uploadUrl` (signed). On success, client calls `POST /api/images/complete` body `{ imageId, s3Key, fileSize, mimeType }`. Server creates/updates `images` record (status=processing) and enqueues QStash job `{ imageId }`. Returns `{ imageId, status: 'processing' }`.
  * **Alternative**: single endpoint `POST /api/images` that accepts multipart upload — currently server handles compression and PUT to S3; we recommend signed PUT for scale.

* `GET /api/images/[id]` — returns image record + `image_metadata` if available.

* `PATCH /api/images/[id]` — update metadata (manual edit) — requires `image_metadata` upsert.

* `DELETE /api/images/[id]` — delete image + cascade metadata + optionally call `decrement_user_image_count` if you decide uploaded images should be refunded.

* `POST /api/images/[id]/regenerate` — enqueue regeneration (consumes quota). Should check quota/reserve before enqueue; return `202 Accepted`.

### Jobs (QStash)

* `POST /api/jobs/process-image` — **QStash webhook**. Security: validate QStash signature header. Body `{ imageId, attempt }`. Processing flow described below.

### Billing & Usage

* `POST /api/billing/create-checkout` — create Stripe Checkout Session (redirect URL returned).
* `POST /api/billing/create-portal` — create Stripe Customer Portal session (redirect).
* `POST /api/webhooks/stripe` — handle relevant Stripe events (`customer.subscription.created/updated/deleted`, `invoice.paid`, `invoice.payment_failed`), map PriceID → subscription_tiers, update `public.users` fields and reset usage when new period begins.

### Admin / Utility

* Server-side only RPC endpoints to call DB functions: `POST /api/admin/reserve` (service role) or server calls directly to Postgres via service connection.

---

# 6. Processor / QStash webhook behavior (detailed)

**Endpoint:** `POST /api/jobs/process-image` — invoked by QStash.

**Security:** Validate QStash signature (QStash signing key) and use service-side secrets for DB/Stripe.

**High-level steps (single request):**

1. Validate signature. Parse `{ imageId }`. Log job start.
2. Fetch `images` row and `collection` and user id from DB (server-side service role).
3. Download image from S3 (signed GET or CloudFront URL).
4. Deterministic analysis:

   * run Sharp: get width, height, orientation, aspect ratio, compress variant(s).
   * run node-vibrant or algorithm for dominant colors (top 5).
   * detect text (Tesseract or vision OCR) optionally for `text_content`.
5. Build an AI request payload with controlled prompts (JSON schema) for semantic analysis: scene description, focal point, style_tags, mood, suggested use cases, text_overlay_safe, safe_text_zones.
6. Call AI provider via **adapter** (provider selection logic). Timeout and retries as needed.
7. **Redaction & encryption:** run regex redaction on AI response to remove emails/phone/SSN/credit-like strings; encrypt the raw response payload (app-level AES-256/GCM or similar) and persist to `ai_responses`. Store optional redacted summary in `redacted_payload`.
8. Parse AI JSON output using strict parser (`lib/ai/parser.ts`) that validates against `ImageMetadata` TypeScript schema/Zod. If invalid, mark failed.
9. Upsert into `image_metadata`.
10. Update `images` row status = `completed`, set processing timestamps, set `cdn_url`.
11. On success: if you used a pre-reserve step that only reserved and didn't increment, call DB RPC `increment_user_image_count` or rely on reserved semantics depending on design. (We recommended atomic reservation earlier — if you used that, you can consider the reservation as committed. If your reservation model only reserved and you want to finalize on success, call `increment_user_image_count`.)
12. Return `200` to QStash.

**Failure semantics:**

* If AI call fails or parsing fails, set `images.status = 'failed'`, include `error_message`. Call `decrement_user_image_count` when appropriate (if you already incremented). QStash will retry according to its configuration. Keep a dead-letter log.

**Idempotency:** ensure repeated calls (QStash retrying) with same `imageId` are idempotent: check `images.status` and `ai_responses` existing entry IDs before creating duplicates (use `ON CONFLICT` patterns with job idempotency keys).

---

# 7. AI Adapter design

Provide an adapter interface so you can plug Anthropic, OpenAI, or other vision providers without changing processing logic.

**Interface (pseudo):**

```ts
interface AiProvider {
  name: string;
  analyzeImage(params: { imageUrl: string, width: number, height: number }): Promise<AiResponse>;
}
```

* `AiResponse` must be parsed into `ImageMetadata` via `lib/ai/parser.ts` that uses a Zod schema to validate and normalize outputs.
* Add provider-specific rate limiting, batching, or cheaper fallbacks (e.g., a cheap text-only model for simpler images).

---

# 8. Client UX flows (detailed)

### Signup / Onboarding

* Use Supabase Auth (email/password + magic links + OAuth). After signup, Supabase triggers `public.users` creation.
* Post-signup flow: onboard modal with plan info and CTA to upload first image; show usage limits.

### Upload flow (for the user)

1. Open collection → click “Upload”.
2. Client requests `GET /api/usage` or `POST /api/usage/preflight` to get user’s `remaining` and `max_bulk_upload` (read from `subscription_tiers.features`). Show message: “You can upload up to X images now.”
3. For N files:

   * Call `POST /api/images/preupload` with all file metadata and requested `count = n`. Server calls `check_and_reserve_slots(user, n)` — if success true, server returns signed PUT URLs (or one pre-signed URL per file). If `success=false`, server returns `remaining` so client can reduce selection.
4. Client PUTs files to S3 concurrently (progress bars). After each successful PUT, client calls `POST /api/images/complete` for each `imageId`.
5. After complete, images appear in grid with status `processing`. Subscribe to Supabase Realtime for updates; show progress "3/20 processed".

### Regenerate metadata

* On image detail: click “Regenerate” — the client should call `check_and_reserve_slots(user, 1)` to reserve (or verify enough usage), then `POST /api/images/[id]/regenerate`. Show confirm modal that it consumes one usage credit.

---

# 9. Billing & Stripe integration (practical)

* Use **Stripe Checkout** (redirect) for initial purchase; return to app on success/failure.
* Use **Stripe Customer Portal** for self-serve billing management (cancel, update card, invoices).
* Keep a mapping table or map PriceID → `subscription_tiers.tier_name` (store `price_monthly` in cents in `subscription_tiers`).
* Implement webhook handler `POST /api/webhooks/stripe` to handle:

  * `customer.subscription.created` / `customer.subscription.updated` → update `stripe_subscription_id`, `subscription_status`, `current_period_start`, `current_period_end`, `subscription_tier`.
  * `invoice.payment_failed` → set `subscription_status = 'past_due'` etc.
  * On period start event, reset `images_used_this_period = 0`.

**Idempotency**: keep processed event IDs table to avoid duplicate handling.

Recommendation: map Stripe Price IDs in `subscription_tiers.features` or a small table `stripe_price_mapping`.

---

# 10. Security & RLS (operational)

### RLS basics (already applied)

* Keep RLS ON for `public.*` tables. Policies:

  * `users` SELECT only if `auth.uid() = id`.
  * `collections` / `images` / `image_metadata` SELECT/INSERT/UPDATE/DELETE must check `auth.uid() = user_id` via join to collections.
  * `subscription_tiers` SELECT allowed for authenticated users.

### Service operations

* Any server action that requires admin privileges (Stripe webhook handling, `check_and_reserve_slots`, increment/decrement) must use the **Supabase service_role** key on server side — never expose it to client.

### Webhook security

* Validate QStash signature; reject if invalid.
* Validate Stripe webhook signature using `STRIPE_WEBHOOK_SECRET`.

### AI outputs & data leakage

* Apply regex-based redaction on AI responses (emails, phone numbers, SSNs, card-like numbers).
* Encrypt `response_payload` at app-level before DB insert (AES-GCM with rotated keys). Store `redacted_payload` as JSON summary for UI/debugging.

### Secrets & key rotation

* Store all secrets in Vercel/Render/Railway secret stores. Rotate quarterly.

---

# 11. Environments & deployment

### Environments

* **Local dev**: run `supabase start`, `next dev`. Use Supabase CLI for migrations & test keys.
* **Staging**: create separate Supabase project + Vercel project (deploy from `staging` branch). Set Stripe test keys for staging.
* **Production**: Vercel production branch + Supabase production project + live Stripe keys.

### Deploying migrations

* Use Supabase Migrations via CLI (`supabase migration create` + `supabase db push`) in CI. Run as service_role in CI (store service_role key in CI secrets). Ensure `pgcrypto` creation and `auth.users` trigger statements are applied with sufficient permissions.

### QStash & Next.js endpoint hosting (MVP)

* QStash will call your Next.js API route `/api/jobs/process-image` on Vercel. If processing times stay below Vercel timeout and Sharp binary works in Vercel environment, continue with this approach. If you run into timeouts or heavy CPU, move to a dedicated worker (Render/Railway/Cloud Run) and update QStash target URL.
* Document the fallback plan: containerize processor and deploy to Render.

---

# 12. Observability & analytics

* **Sentry**: instrument Next.js, API routes, processors. Upload source maps. Include user context (hashed user ID) in error reports.
* **Plausible**: basic usage analytics (traffic, referrers). Events to log: signup, upload started, upload completed, metadata generated, regenerate, checkout success.
* **Optional later**: PostHog for feature-based product analytics and funnels (self-host if budget constrained).

---

# 13. Cost & optimization notes

* AI calls will dominate variable costs. Consider:

  * Preprocessing cheap operations locally (color extraction, dimensions) to reduce AI calls.
  * Lazy generation for long-tail images (only generate metadata on view or on-demand).
  * Use cheaper models for simple images or for initial drafts, higher-cost models for final outputs.
* Store `ai_responses` retention to limit storage cost (90 days by default).

---

# 14. Implementation plan — week-by-week (split into user stories / tasks)

This is a suggested sprintable plan for a solo developer (approx 5–6 weeks). Each bullet can be translated into multiple user stories.

### Week 0 — Prep & infra (pre-sprint)

* Create Git repo, CI pipeline, issue tracker.
* Create Supabase dev project and Vercel dev project.
* Implement migration folder and add `pgcrypto` + base tables + triggers.

### Week 1 — Auth, DB, and basic UI shell

* Task: Wire Supabase Auth in Next.js (signup/signin/magic link/OAuth).
* Task: Implement `handle_new_user` trigger; verify `public.users` creation.
* Task: Create DB migrations for `subscription_tiers` seeds, `ai_responses` schema, RPCs (`check_and_reserve_slots`, `decrement_user_image_count`).
* Task: Implement basic dashboard layout, login flow, and account page.

Deliverable: Working auth + `public.users` created on signup.

### Week 2 — Collections & upload preflight

* Task: Implement collections CRUD (API routes + frontend).
* Task: Implement `get_user_quota` read RPC and UI display.
* Task: Implement `preupload` endpoint that calls `check_and_reserve_slots` and returns signed PUT URLs.
* Task: Implement client upload UI with react-dropzone & progress. Enforce free vs pro limits via `subscription_tiers.features.max_bulk_upload` (default 20 for pro).

Deliverable: Users can create collections and upload to S3 with reservation flow.

### Week 3 — QStash + processing pipeline MVP

* Task: Configure QStash; create job format `{ imageId }`.
* Task: Implement `/api/jobs/process-image` Next.js route: signature validation, download S3, Sharp color extraction, store basic metadata, write `images` status updates.
* Task: Implement AI adapter skeleton (provider interface); call a cheap model stub for dev.
* Task: Store raw AI responses encrypted into `ai_responses` and parse into `image_metadata`.

Deliverable: Images process end-to-end; metadata stored; UI shows metadata.

### Week 4 — UI polish, metadata editing & export

* Task: Implement MetadataDisplay + MetadataEditor UI with Zod validation.
* Task: Implement regenerate flow (check quota, enqueue QStash job).
* Task: Implement JSON export for collections.
* Task: Implement usage bar & billing upgrade CTA.

Deliverable: Metadata editing & export working.

### Week 5 — Billing, webhooks, production readiness

* Task: Implement Stripe Checkout redirection flow + Customer Portal.
* Task: Implement `POST /api/webhooks/stripe` to sync subscription info + reset usage.
* Task: Add Sentry + Plausible instrumentation.
* Task: Migrate staging → production: run migrations via `supabase db push` in CI with service_role, set production env vars on Vercel, run smoke tests.

Deliverable: Billing integrated; production deployable MVP.

### Post-MVP / future tasks

* Add org/team support (organizations table + RLS).
* Add dedicated worker (Render/Railway) and migrate QStash webhook target.
* Add PostHog if product analytics required.
* Add BYOK and external API product features.

---

# 15. User stories (sample, ready to import into backlog)

* As a user, I can sign up and sign in using email and magic link so I can access my dashboard.
* As a user, I can create a collection with a name and description so I can group images.
* As a free user, I can upload 1 image at a time; as a pro user I can upload up to 20 images per batch. The UI should show how many uploads are allowed now.
* As a user, after uploading an image I can see `processing` status and a progress indicator until metadata is available.
* As a user, I can view generated metadata (description, alt_text, keywords, colors, focal_point, suggested_use_cases) for an image.
* As a user, I can edit any metadata field and save changes.
* As a user, I can click regenerate to request new metadata (consumes quota).
* As a user, I can export my collection as formatted JSON containing CDN URLs and metadata.
* As an admin/system, Stripe webhooks update user subscription data and reset usage on period start.
* As a developer, I can run the migration scripts in CI and deploy to production with managed secrets.

Each of these can be decomposed into tasks (API route, DB change, frontend component, tests).

---

# 16. Security checklist (developer copy)

* [ ] Supabase RLS enforced for `public` tables.
* [ ] Service role key never exposed to client — store in server env only.
* [ ] QStash signature validated in `/api/jobs/process-image`.
* [ ] Stripe webhook signature validated.
* [ ] `ai_responses` encrypted; retention purge job runs daily.
* [ ] Secrets rotated periodically.
* [ ] Sentry integrated; alerts configured for processing failures.
* [ ] Configure CloudFront to serve images and restrict S3 to CloudFront origin/ signed URLs.

---

# 17. Where to change bulk upload & related configs

* **Bulk upload limit**: change in `public.subscription_tiers.features.max_bulk_upload`. No schema change required. Update seed or run:

```sql
UPDATE public.subscription_tiers
SET features = jsonb_set(features, '{max_bulk_upload}', '20'::jsonb)
WHERE tier_name = 'pro';
```

* **AI retention**: modify the purge SQL interval.
* **Quota logic**: change `subscription_tiers.images_per_period`.

---

# 18. Redaction & encryption (implementation notes)

* **Regex redaction (MVP)**: implement in processor:

  * Remove patterns: email, international phone, credit-card-like numbers, SSN-like patterns. Replace with `[REDACTED]`.
* **Encryption**: encrypt raw model response before INSERT using app-level AES-256-GCM. Store key in env var (rotate occasionally).
* **Read access**: Only return `redacted_payload` or parsed `image_metadata` to frontend.

Example Node snippet (conceptual):

```ts
// pseudo
const redacted = redact(responseText);
const ciphertext = encryptAESGCM(responseText, process.env.AI_RESPONSE_KEY);
await db.insert('ai_responses', { image_id, provider, model, request_payload, response_payload: ciphertext, redacted_payload: JSON.parse(redactedSummary) });
```

---

# 19. Migration & CI note

* Use Supabase CLI & migrations folder in Git. In your CI pipeline, run `supabase db push` using a job that is provisioned with the service_role key (store it safe in CI secrets). Test migrations in staging before production.

---

# 20. Scalability path (short)

1. If processors start timing out on Vercel, deploy a dedicated worker (Render/Railway/Cloud Run). QStash target simply changes to worker URL.
2. Move heavy preprocessing to dedicated worker or break jobs into chained QStash jobs.
3. Add Redis/BullMQ for internal job queue if you need more complex orchestration.
4. Add caching for repeated image metadata (hash of image content → reuse metadata to reduce costs).

---

# 21. Deliverables included (in this response)

* Full Architecture Document v2 (this file): architecture, SQL snippets, RPCs, API endpoints, processing flow, security, and deployment notes.
* Concrete SQL snippets for:

  * `CREATE EXTENSION` (pgcrypto)
  * `handle_new_user` trigger
  * `ai_responses` table
  * `check_and_reserve_slots` RPC
  * `decrement_user_image_count` RPC
  * purge SQL (90 days)
* Frontend UX flows and where to call DB RPCs for quota/reservation.
* Implementation timeline and sample user stories ready to be split into tasks.