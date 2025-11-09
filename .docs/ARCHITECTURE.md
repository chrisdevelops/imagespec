# Architecture Document: Image Metadata Generation SaaS
## Project Overview

**Product Name:** ImageSpec

**Tagline:** AI-powered metadata for better web design

**Problem Statement:**
AI models excel at generating semantic HTML and content but struggle with design decisions regarding asset placement and usage. They lack visual context about images - dimensions, color schemes, focal points, and appropriate use cases.

**Solution:**
A service that automatically generates comprehensive, structured metadata for images, providing AI developers with the visual context they need to make informed design decisions.

**Target Market:**
- AI-native web developers using Claude Code, Cursor, etc.
- Web design agencies building multiple client sites
- Freelance developers creating AI-assisted workflows
- Marketing teams managing asset libraries

**Business Model:**
Freemium SaaS with managed infrastructure (Phase 1), optional BYOK (Bring Your Own Keys) in Phase 2.

---

## MVP Feature Set

### Core Features (Must-Have for Launch)

#### 1. Authentication & Account Management
- **Email/password authentication** with secure password hashing (bcrypt)
- **Magic link authentication** for passwordless login (reduced friction)
- Password reset flow via email
- Basic user profile management (name, email)
- Account deletion with data cleanup (GDPR compliance)
- Session management via JWT tokens

#### 2. Collections Management
- **Create collection** with name and optional description
- **List all user collections** with image count and metadata
- **Delete collection** with cascade delete of all contained images (with confirmation)
- **View collection details** with all images and their metadata
- Collections serve as organizational units for projects/clients/campaigns

#### 3. Image Upload & Processing
- **Drag-and-drop interface** for intuitive UX
- **Multi-file upload** support (up to 10 images simultaneously)
- **Supported formats:** JPG, PNG, WebP
- **File size limit:** 10MB per image
- **Real-time upload progress** indicators
- **Automatic processing pipeline:**
  1. Client-side file validation
  2. Image compression (target 200-500KB without visible quality loss)
  3. Upload to S3 with unique keys
  4. Database record creation (status: "processing")
  5. Background job queuing for metadata generation
  6. Status polling from client

#### 4. AI-Powered Metadata Generation
Uses Claude 3.5 Sonnet to analyze images and generate:

**Descriptive Metadata:**
- `description` - Detailed description of image contents, composition, lighting, mood
- `alt_text` - Accessibility-focused alternative text
- `content_keywords` - Array of relevant keywords for search/matching

**Visual Analysis:**
- `colors.dominant` - Array of top 5 hex color codes with percentages
- `colors.palette_mood` - Classification: warm/cool/neutral/vibrant
- `colors.overall_tone` - light/mid/dark
- `dimensions` - Width, height, aspect ratio, orientation

**Style & Mood:**
- `style_tags` - Array of style descriptors (e.g., "modern", "minimal", "rustic")
- `mood` - Array of mood descriptors (e.g., "calm", "energetic", "professional")
- `visual_weight` - light/medium/heavy (how visually busy)
- `formality_level` - casual/semi-formal/formal/luxury

**Compositional Data:**
- `focal_point` - Where viewer's eye naturally goes (center/left/right/top/bottom/distributed)
- `subject_type` - Classification of main subject (person/product/landscape/abstract/etc.)
- `background_complexity` - simple/moderate/complex
- `negative_space` - minimal/moderate/abundant

**Functional Metadata:**
- `text_overlay_safe` - Boolean indicating if text can be safely overlaid
- `safe_text_zones` - Array of zones where text won't obscure important content
- `suggested_use_cases` - Array of recommended uses (hero/background/thumbnail/etc.)
- `text_content` - Any text detected within the image (nullable)

#### 5. Manual Metadata Editing
- **Edit any metadata field** after AI generation
- **Field-specific editors:**
  - Text fields with validation
  - Array fields with add/remove functionality
  - Boolean toggles
  - Dropdown selectors for constrained values
- **Regenerate metadata** button (consumes another AI credit, reprocesses image)
- **Real-time preview** of changes
- **Save/cancel** actions with optimistic UI updates

#### 6. JSON Export
- **"Copy JSON" button** at collection level
- Exports complete collection with all images and metadata
- **Format:** Clean, formatted JSON (not minified)
- Includes:
  - Collection metadata
  - Array of all images with full metadata
  - CDN URLs ready for use
- **Success notification** with toast/alert
- **Optional:** Download as .json file

#### 7. Image Management
- **View individual image** with full metadata display
- **Delete individual image** with confirmation
- **Download original image** (from CDN)
- **Copy image CDN URL** to clipboard
- **View usage statistics** (bandwidth consumed - future phase)
- **Image thumbnail grid view** in collections

#### 8. Usage Limits & Billing
- **Usage tracking:** Images uploaded this billing period
- **Visual progress bar** showing current usage vs. limit
- **Upgrade prompts** when approaching limit (80%, 100%)
- **Stripe integration** for subscription management
- **Subscription tiers:**
  - **Free:** 25 images/month, $0
  - **Pro:** 500 images/month, $29/month
- **Cancel anytime** with immediate effect
- **Usage resets** monthly on subscription anniversary
- **Overage handling:** Soft block (upgrade to continue)

---

## Technical Architecture

### High-Level System Design

```
┌─────────────────────────────────────────────────────────────┐
│                         User Browser                         │
└───────────────┬─────────────────────────────────────────────┘
                │ HTTPS
                ▼
┌─────────────────────────────────────────────────────────────┐
│                    Cloudflare CDN Proxy                      │
│              (SSL termination, DDoS protection)              │
└───────────────┬─────────────────────────────────────────────┘
                │
                ▼
┌─────────────────────────────────────────────────────────────┐
│                     Vercel Edge Network                      │
│                      (Next.js App)                           │
│                                                              │
│  ┌────────────────┐  ┌────────────────┐  ┌───────────────┐ │
│  │   Frontend     │  │  API Routes    │  │  Middleware   │ │
│  │  (React/Next)  │  │  (/api/*)      │  │  (Auth)       │ │
│  └────────────────┘  └────────────────┘  └───────────────┘ │
└───────┬───────────────────┬──────────────────┬─────────────┘
        │                   │                  │
        │                   │                  │
        ▼                   ▼                  ▼
┌──────────────┐    ┌──────────────┐   ┌──────────────┐
│  CloudFront  │    │  PostgreSQL  │   │   QStash     │
│  (S3 CDN)    │    │  (Supabase)  │   │  (Queue)     │
│              │    │              │   │              │
│  - Images    │    │  - Users     │   │  - Jobs      │
│  - Assets    │    │  - Collections│   │  - Retries  │
└──────────────┘    │  - Images    │   └──────┬───────┘
                    │  - Metadata  │          │
                    └──────────────┘          │
                                              │ Webhook callback
                                              ▼
                                    ┌──────────────────┐
                                    │   API Route      │
                                    │ /api/jobs/       │
                                    │ process-image    │
                                    └─────────┬────────┘
                                              │
                                              ▼
                                    ┌──────────────────┐
                                    │  External APIs   │
                                    │                  │
                                    │  - Claude API    │
                                    │  - Sharp (local) │
                                    └──────────────────┘
```

### Request Flow Examples

#### Image Upload Flow
```
1. User selects files in browser
   ↓
2. Client validates files (size, type)
   ↓
3. POST /api/images/upload (multipart/form-data)
   ↓
4. Next.js API route receives upload
   ├─→ Compress image with Sharp
   ├─→ Generate unique S3 key
   ├─→ Upload to S3
   ├─→ Create DB record (status: "processing")
   ├─→ Queue job in QStash
   └─→ Return response to client (2-3 seconds)
   ↓
5. Client receives response { imageId, status: "processing" }
   ↓
6. Client starts polling GET /api/images/[id]
   ↓
   ╔═══════════════════ ASYNC BOUNDARY ═══════════════════╗
   ║                                                       ║
   ║ 7. QStash waits ~5 seconds                           ║
   ║    ↓                                                  ║
   ║ 8. QStash calls POST /api/jobs/process-image         ║
   ║    ↓                                                  ║
   ║ 9. Job handler executes:                             ║
   ║    ├─→ Fetch image record from DB                    ║
   ║    ├─→ Download image from S3                        ║
   ║    ├─→ Call Claude API (10-15 seconds)               ║
   ║    ├─→ Extract colors with Sharp                     ║
   ║    ├─→ Combine metadata                              ║
   ║    ├─→ Update DB (status: "completed")               ║
   ║    └─→ Return 200 OK to QStash                       ║
   ║                                                       ║
   ╚═══════════════════════════════════════════════════════╝
   ↓
10. Client poll receives { status: "completed", metadata: {...} }
    ↓
11. UI updates with metadata display
```

#### Collection Export Flow
```
1. User clicks "Copy JSON" button
   ↓
2. GET /api/collections/[id]/export
   ↓
3. Server queries all images in collection with metadata
   ↓
4. Formats as JSON structure
   ↓
5. Returns JSON response
   ↓
6. Client copies to clipboard
   ↓
7. Shows success toast
```

---

## Tech Stack

### Frontend

**Framework:** Next.js 14+ (App Router)
- **Rationale:** 
  - Full-stack React framework with excellent DX
  - Server components for optimal performance
  - Built-in API routes eliminate need for separate backend
  - File-based routing is intuitive
  - Strong TypeScript support
  - Excellent deployment on Vercel

**Styling:** Tailwind CSS v3
- **Rationale:**
  - Utility-first CSS for rapid development
  - Excellent defaults and design system
  - Small bundle size with purging
  - Easy to customize and extend
  - Great documentation

**Component Library:** shadcn/ui
- **Rationale:**
  - Beautiful, accessible components
  - Built on Radix UI primitives
  - Copy-paste components (not NPM dependency)
  - Fully customizable
  - TypeScript-first

**State Management:** Zustand
- **Rationale:**
  - Minimal boilerplate
  - Simple API
  - Good TypeScript support
  - Sufficient for app complexity
  - Alternative: React Query for server state

**File Upload:** react-dropzone
- **Rationale:**
  - Best-in-class drag-and-drop UX
  - Built-in validation
  - Preview support
  - Mobile-friendly
  - Accessible

**Forms:** React Hook Form + Zod
- **Rationale:**
  - Performant (uncontrolled components)
  - Excellent validation with Zod schemas
  - TypeScript integration
  - Reduced re-renders

**HTTP Client:** Native fetch + React Query (TanStack Query)
- **Rationale:**
  - No extra dependencies for basic fetch
  - React Query for caching, refetching, optimistic updates
  - Excellent DevTools

### Backend

**Framework:** Next.js API Routes (App Router)
- **Rationale:**
  - Same codebase as frontend
  - Serverless-ready
  - Type-safe API contracts
  - Easy local development

**Database:** PostgreSQL via Neon or Supabase
- **Neon:**
  - Serverless Postgres with generous free tier
  - Excellent DX with branching
  - Auto-scaling
  - Great for development
- **Supabase:**
  - Postgres + built-in Auth + Storage
  - Real-time subscriptions (if needed later)
  - Generous free tier
  - Excellent dashboard
- **Decision:** Start with Neon for simplicity, migrate to Supabase if auth or storage features become valuable

**ORM:** Prisma
- **Rationale:**
  - Excellent TypeScript support
  - Type-safe queries
  - Great migration system
  - Auto-generated client
  - Introspection and seeding support

**Authentication:** NextAuth.js v5 (Auth.js)
- **Rationale:**
  - Built for Next.js App Router
  - Magic link support out of box
  - Extensible providers
  - Session management
  - Secure by default

**File Storage:** AWS S3 + CloudFront
- **Rationale:**
  - Industry standard, battle-tested
  - 99.999999999% durability
  - Excellent ecosystem support
  - CloudFront CDN built-in
  - Predictable pricing
- **Alternative:** Cloudflare R2 if costs become concern

**Background Jobs:** Upstash QStash
- **Rationale:**
  - Serverless-native (no persistent processes needed)
  - HTTP-based, works anywhere
  - Built-in retries and failure handling
  - Dead letter queue
  - Generous free tier (500 jobs/day)
  - Monitoring dashboard included

**AI Provider:** Anthropic Claude API
- **Model:** Claude 3.5 Sonnet (`claude-3-5-sonnet-20241022`)
- **Rationale:**
  - Excellent vision capabilities
  - Reliable and fast
  - Good pricing (~$0.10 per image analyzed)
  - Strong JSON output support

**Image Processing:** Sharp (Node.js)
- **Rationale:**
  - Fast, reliable native library
  - Comprehensive format support
  - Handles compression, resizing, format conversion
  - Color extraction capabilities

**Color Extraction:** node-vibrant + Sharp
- **Rationale:**
  - Accurate dominant color detection
  - Fast processing
  - Integrates well with Sharp pipeline

**Payment Processing:** Stripe
- **Rationale:**
  - Industry standard
  - Excellent documentation
  - Robust webhook system
  - Stripe Checkout for simple flow
  - Built-in subscription management

### Infrastructure & Deployment

**Hosting:** Vercel
- **Rationale:**
  - Made by Next.js team
  - Zero-config deployment
  - Excellent DX with preview deployments
  - Generous free tier (Hobby plan)
  - Built-in Edge Functions
  - Automatic HTTPS

**CDN:** Cloudflare (proxy in front of Vercel)
- **Rationale:**
  - Free tier is excellent
  - Additional security layer (DDoS protection)
  - Better caching control
  - Analytics included
- **Alternative:** Just use Vercel's built-in CDN initially

**Monitoring:** Sentry
- **Rationale:**
  - Error tracking with stack traces
  - Performance monitoring
  - Release tracking
  - Free tier sufficient for MVP
  - Excellent Next.js integration

**Analytics:** Plausible or PostHog
- **Rationale:**
  - Privacy-friendly (GDPR compliant)
  - Simple, focused metrics
  - No cookie banner needed
  - Self-hostable option
- **Alternative:** Google Analytics if preferred

**Email:** Resend
- **Rationale:**
  - Modern, developer-friendly API
  - React email templates
  - Generous free tier (100 emails/day)
  - Excellent deliverability
  - Built-in analytics

### Development Tools

**Version Control:** Git + GitHub
- GitHub Actions for CI/CD

**Code Quality:**
- ESLint (linting)
- Prettier (formatting)
- Husky (pre-commit hooks)
- TypeScript strict mode

**Package Manager:** pnpm
- **Rationale:** Faster than npm/yarn, efficient disk usage

**Testing:** (Optional for MVP, add post-launch)
- Vitest for unit tests
- Playwright for E2E tests

---

## Database Schema

### Prisma Schema

```prisma
// prisma/schema.prisma

generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

// ============================================
// USER & AUTH
// ============================================

model User {
  id            String       @id @default(cuid())
  email         String       @unique
  name          String?
  passwordHash  String?      // Null for magic link only users
  emailVerified DateTime?
  
  // Subscription & Billing
  stripeCustomerId     String?   @unique
  stripePriceId        String?   // Current plan price ID
  stripeSubscriptionId String?   @unique
  subscriptionStatus   String?   // active, canceled, past_due, trialing
  currentPeriodStart   DateTime?
  currentPeriodEnd     DateTime?
  
  // Usage Tracking
  imageCount           Int       @default(0)    // Images uploaded this billing period
  usageResetAt         DateTime  @default(now()) // When to reset count
  maxImages            Int       @default(25)    // Based on plan
  
  // Relationships
  collections          Collection[]
  sessions             Session[]
  
  // Timestamps
  createdAt            DateTime  @default(now())
  updatedAt            DateTime  @updatedAt
  
  @@index([email])
}

model Session {
  id           String   @id @default(cuid())
  sessionToken String   @unique
  userId       String
  expires      DateTime
  user         User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  
  createdAt    DateTime @default(now())
  updatedAt    DateTime @updatedAt
  
  @@index([userId])
}

model VerificationToken {
  identifier String
  token      String   @unique
  expires    DateTime
  
  @@unique([identifier, token])
}

// ============================================
// COLLECTIONS & IMAGES
// ============================================

model Collection {
  id          String   @id @default(cuid())
  name        String
  description String?  @db.Text
  
  // Ownership
  user        User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  userId      String
  
  // Relationships
  images      Image[]
  
  // Timestamps
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt
  
  @@index([userId])
  @@index([createdAt])
}

model Image {
  id           String   @id @default(cuid())
  
  // File Information
  filename     String                // Generated safe filename
  originalName String                // User's original filename
  fileSize     Int                   // Bytes
  mimeType     String                // image/jpeg, image/png, etc.
  
  // Storage URLs
  s3Key        String   @unique      // S3 object key
  s3Url        String                // S3 direct URL
  cdnUrl       String                // CloudFront public URL
  
  // Dimensions (extracted during upload)
  width        Int
  height       Int
  aspectRatio  String                // e.g., "16:9", "4:3", "1:1"
  orientation  String                // "landscape", "portrait", "square"
  
  // AI-Generated Metadata (stored as JSONB)
  metadata     Json?                 // All metadata fields as JSON object
  
  // Processing Status
  status       String   @default("processing") // "processing", "completed", "failed"
  errorMessage String?  @db.Text     // Error details if failed
  processingStartedAt DateTime?
  processingCompletedAt DateTime?
  
  // Relationships
  collection   Collection @relation(fields: [collectionId], references: [id], onDelete: Cascade)
  collectionId String
  
  // Timestamps
  createdAt    DateTime @default(now())
  updatedAt    DateTime @updatedAt
  
  @@index([collectionId])
  @@index([status])
  @@index([createdAt])
}

// ============================================
// BACKGROUND JOBS (Optional tracking)
// ============================================

model Job {
  id          String   @id @default(cuid())
  type        String                 // "process-image", etc.
  payload     Json                   // Job data
  status      String   @default("pending") // "pending", "processing", "completed", "failed"
  attempts    Int      @default(0)
  maxAttempts Int      @default(3)
  error       String?  @db.Text
  
  // Timestamps
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt
  completedAt DateTime?
  
  @@index([status])
  @@index([type])
}
```

### Metadata JSON Structure

The `Image.metadata` field stores JSON with this structure:

```typescript
interface ImageMetadata {
  // Descriptive
  description: string;
  alt_text: string;
  content_keywords: string[];
  
  // Visual Analysis
  colors: {
    dominant: string[];           // Array of hex codes
    palette_mood: 'warm' | 'cool' | 'neutral' | 'vibrant';
    overall_tone: 'light' | 'mid' | 'dark';
  };
  
  // Style & Mood
  style_tags: string[];           // e.g., ["modern", "minimal", "rustic"]
  mood: string[];                 // e.g., ["calm", "professional", "inviting"]
  visual_weight: 'light' | 'medium' | 'heavy';
  formality_level: 'casual' | 'semi-formal' | 'formal' | 'luxury';
  
  // Compositional
  focal_point: 'center' | 'left' | 'right' | 'top' | 'bottom' | 'distributed';
  subject_type: string;           // "person", "product", "landscape", etc.
  background_complexity: 'simple' | 'moderate' | 'complex';
  negative_space: 'minimal' | 'moderate' | 'abundant';
  
  // Functional
  text_overlay_safe: boolean;
  safe_text_zones: string[];      // e.g., ["top-left", "bottom-right"]
  suggested_use_cases: string[];  // e.g., ["hero", "background", "thumbnail"]
  text_content: string | null;    // Any text found in image
  
  // Technical
  optimal_background: 'light' | 'dark' | 'neutral';
}
```

---

## Project Structure

```
project-root/
├── app/                          # Next.js App Router
│   ├── (auth)/                   # Auth route group (different layout)
│   │   ├── login/
│   │   │   └── page.tsx
│   │   ├── signup/
│   │   │   └── page.tsx
│   │   ├── reset-password/
│   │   │   └── page.tsx
│   │   └── layout.tsx            # Auth-specific layout
│   │
│   ├── (dashboard)/              # Dashboard route group
│   │   ├── collections/
│   │   │   ├── page.tsx          # List collections
│   │   │   ├── [id]/
│   │   │   │   ├── page.tsx      # Collection detail
│   │   │   │   └── edit/
│   │   │   │       └── page.tsx
│   │   │   └── new/
│   │   │       └── page.tsx
│   │   ├── settings/
│   │   │   └── page.tsx
│   │   ├── billing/
│   │   │   └── page.tsx
│   │   └── layout.tsx            # Dashboard layout with nav
│   │
│   ├── api/                      # API Routes
│   │   ├── auth/
│   │   │   └── [...nextauth]/
│   │   │       └── route.ts      # NextAuth configuration
│   │   ├── collections/
│   │   │   ├── route.ts          # GET, POST /api/collections
│   │   │   └── [id]/
│   │   │       ├── route.ts      # GET, PATCH, DELETE /api/collections/[id]
│   │   │       ├── export/
│   │   │       │   └── route.ts  # GET /api/collections/[id]/export
│   │   │       └── images/
│   │   │           └── route.ts  # GET /api/collections/[id]/images
│   │   ├── images/
│   │   │   ├── route.ts          # POST /api/images (upload)
│   │   │   └── [id]/
│   │   │       ├── route.ts      # GET, PATCH, DELETE /api/images/[id]
│   │   │       └── regenerate/
│   │   │           └── route.ts  # POST /api/images/[id]/regenerate
│   │   ├── jobs/
│   │   │   └── process-image/
│   │   │       └── route.ts      # POST (QStash webhook)
│   │   ├── webhooks/
│   │   │   └── stripe/
│   │   │       └── route.ts      # POST (Stripe webhooks)
│   │   └── usage/
│   │       └── route.ts          # GET current user usage
│   │
│   ├── layout.tsx                # Root layout
│   ├── page.tsx                  # Landing page
│   ├── globals.css               # Global styles
│   └── providers.tsx             # Context providers wrapper
│
├── components/                   # React components
│   ├── ui/                       # shadcn/ui components
│   │   ├── button.tsx
│   │   ├── input.tsx
│   │   ├── dialog.tsx
│   │   ├── dropdown-menu.tsx
│   │   ├── toast.tsx
│   │   └── ...
│   ├── auth/
│   │   ├── LoginForm.tsx
│   │   ├── SignupForm.tsx
│   │   └── MagicLinkForm.tsx
│   ├── collections/
│   │   ├── CollectionCard.tsx
│   │   ├── CollectionGrid.tsx
│   │   ├── CreateCollectionDialog.tsx
│   │   └── DeleteCollectionDialog.tsx
│   ├── images/
│   │   ├── ImageUploader.tsx     # Drag-drop component
│   │   ├── ImageCard.tsx
│   │   ├── ImageGrid.tsx
│   │   ├── ImageStatusBadge.tsx
│   │   ├── MetadataDisplay.tsx
│   │   ├── MetadataEditor.tsx
│   │   └── ExportButton.tsx
│   ├── billing/
│   │   ├── PricingTable.tsx
│   │   ├── UsageBar.tsx
│   │   └── UpgradePrompt.tsx
│   └── layouts/
│       ├── DashboardNav.tsx
│       ├── UserMenu.tsx
│       └── Footer.tsx
│
├── lib/                          # Utility functions & configs
│   ├── db/
│   │   ├── prisma.ts             # Prisma client singleton
│   │   └── migrations/
│   ├── storage/
│   │   ├── s3.ts                 # S3 upload/download utilities
│   │   └── compression.ts        # Image compression with Sharp
│   ├── ai/
│   │   ├── claude.ts             # Claude API integration
│   │   ├── prompts.ts            # Metadata generation prompts
│   │   └── parser.ts             # Parse Claude JSON responses
│   ├── jobs/
│   │   ├── qstash.ts             # QStash client setup
│   │   └── handlers/
│   │       └── process-image.ts  # Image processing job logic
│   ├── stripe/
│   │   ├── client.ts             # Stripe client
│   │   ├── webhooks.ts           # Webhook handlers
│   │   └── plans.ts              # Plan definitions
│   ├── auth/
│   │   ├── config.ts             # NextAuth configuration
│   │   └── session.ts            # Session utilities
│   ├── colors/
│   │   └── extractor.ts          # Color extraction with node-vibrant
│   ├── email/
│   │   ├── client.ts             # Resend client
│   │   └── templates/
│   │       ├── magic-link.tsx
│   │       └── welcome.tsx
│   ├── utils/
│   │   ├── cn.ts                 # Class name utilities
│   │   ├── format.ts             # Date, number formatting
│   │   └── validation.ts         # Zod schemas
│   └── constants.ts              # App-wide constants
│
├── prisma/
│   ├── schema.prisma             # Database schema
│   ├── migrations/               # Migration history
│   └── seed.ts                   # Database seeding
│
├── public/
│   ├── images/
│   ├── fonts/
│   └── favicon.ico
│
├── types/
│   ├── metadata.ts               # TypeScript types for metadata
│   ├── api.ts                    # API request/response types
│   └── database.ts               # Prisma-generated types (augmented)
│
├── .env.local                    # Local environment variables
├── .env.example                  # Example env file for setup
├── .eslintrc.json
├── .prettierrc
├── next.config.js
├── tailwind.config.ts
├── tsconfig.json
├── package.json
└── README.md
```

---

## Environment Variables

```bash
# .env.example

# Database
DATABASE_URL="postgresql://user:password@host:5432/dbname"

# NextAuth
NEXTAUTH_URL="http://localhost:3000"
NEXTAUTH_SECRET="generate-random-secret"

# AWS S3
AWS_REGION="us-east-1"
AWS_ACCESS_KEY_ID="your-access-key"
AWS_SECRET_ACCESS_KEY="your-secret-key"
AWS_S3_BUCKET="your-bucket-name"
AWS_CLOUDFRONT_DOMAIN="d1234567890.cloudfront.net"

# Anthropic Claude
ANTHROPIC_API_KEY="sk-ant-..."

# Upstash QStash
QSTASH_URL="https://qstash.upstash.io"
QSTASH_TOKEN="your-qstash-token"
QSTASH_CURRENT_SIGNING_KEY="your-signing-key"
QSTASH_NEXT_SIGNING_KEY="your-next-signing-key"

# Stripe
STRIPE_SECRET_KEY="sk_test_..."
STRIPE_PUBLISHABLE_KEY="pk_test_..."
STRIPE_WEBHOOK_SECRET="whsec_..."
STRIPE_PRICE_ID_PRO="price_..."

# Resend Email
RESEND_API_KEY="re_..."
RESEND_FROM_EMAIL="noreply@yourdomain.com"

# App URLs
NEXT_PUBLIC_APP_URL="http://localhost:3000"

# Feature Flags (optional)
NEXT_PUBLIC_ENABLE_MAGIC_LINK="true"
NEXT_PUBLIC_ENABLE_SOCIAL_AUTH="false"
```

---

## API Endpoints

### Authentication
- `POST /api/auth/signup` - Create new account
- `POST /api/auth/signin` - Sign in with email/password
- `POST /api/auth/magic-link` - Request magic link
- `POST /api/auth/signout` - Sign out
- `POST /api/auth/reset-password` - Request password reset
- `POST /api/auth/reset-password/confirm` - Confirm new password

### Collections
- `GET /api/collections` - List user's collections
- `POST /api/collections` - Create new collection
- `GET /api/collections/[id]` - Get collection details
- `PATCH /api/collections/[id]` - Update collection
- `DELETE /api/collections/[id]` - Delete collection
- `GET /api/collections/[id]/export` - Export collection as JSON
- `GET /api/collections/[id]/images` - List images in collection

### Images
- `POST /api/images` - Upload new images (multipart/form-data)
- `GET /api/images/[id]` - Get image details and metadata
- `PATCH /api/images/[id]` - Update image metadata
- `DELETE /api/images/[id]` - Delete image
- `POST /api/images/[id]/regenerate` - Regenerate metadata

### Background Jobs (Internal)
- `POST /api/jobs/process-image` - QStash webhook for processing

### Webhooks (External)
- `POST /api/webhooks/stripe` - Stripe webhook events

### Usage & Billing
- `GET /api/usage` - Get current user usage stats
- `POST /api/billing/create-checkout` - Create Stripe checkout session
- `POST /api/billing/create-portal` - Create Stripe customer portal session

---

## Security Considerations

### Authentication & Authorization
- **Password hashing:** bcrypt with salt rounds of 12
- **Session tokens:** Secure, HTTP-only cookies
- **Magic links:** Time-limited tokens (15 minutes), single-use
- **API routes:** Protected with middleware checking session
- **Rate limiting:** Implement per-user rate limits on uploads

### File Upload Security
- **File type validation:** Client-side AND server-side
- **File size limits:** 10MB hard limit
- **Virus scanning:** Consider ClamAV integration (post-MVP)
- **Unique filenames:** Generate UUIDs to prevent collisions/overwrites
- **S3 bucket:** Private by default, served via signed URLs or CloudFront

### API Security
- **QStash webhooks:** Verify signatures to ensure authenticity
- **Stripe webhooks:** Verify signatures
- **CORS:** Restrictive CORS policy
- **Rate limiting:** Use Upstash Rate Limit or Vercel rate limiting
- **Input validation:** Zod schemas on all API inputs

### Data Privacy
- **GDPR compliance:** User can delete account and all data
- **Data encryption:** At rest (S3, database) and in transit (HTTPS)
- **No third-party tracking:** Privacy-friendly analytics only
- **Clear privacy policy:** Required for Stripe compliance

### Environment Variables
- **Never commit:** Use .env.local (gitignored)
- **Vercel secrets:** Store production secrets in Vercel dashboard
- **Rotation:** Rotate API keys quarterly

---

## Performance Optimization

### Image Delivery
- **CDN:** CloudFront for global edge caching
- **Compression:** Serve WebP when supported, fall back to JPEG
- **Lazy loading:** Images load only when visible
- **Responsive images:** Use Next.js Image component with srcset

### Database
- **Indexes:** On frequently queried fields (userId, collectionId, status)
- **Connection pooling:** Prisma handles this automatically
- **Pagination:** Cursor-based pagination for large result sets
- **Caching:** Consider Redis cache for hot data (post-MVP)

### Frontend
- **Code splitting:** Automatic with Next.js
- **Static generation:** Landing page is statically generated
- **Server components:** Use where possible to reduce client bundle
- **Optimize fonts:** Use next/font for automatic font optimization

### API Routes
- **Streaming:** Use streaming responses for large JSON exports
- **Compression:** Enable gzip/brotli compression
- **Edge functions:** Deploy performance-critical routes to edge

---

## Monitoring & Observability

### Error Tracking
- **Sentry:** Capture unhandled errors, API failures
- **Source maps:** Upload source maps for readable stack traces
- **User context:** Include user ID (hashed) in error reports
- **Release tracking:** Tag errors with release version

### Performance Monitoring
- **Sentry Performance:** Track API response times, database queries
- **Core Web Vitals:** Monitor LCP, FID, CLS
- **Custom metrics:** Track image processing times, AI API latency

### Logs
- **Vercel logs:** Access request logs in Vercel dashboard
- **Structured logging:** Use consistent log format with context
- **Log levels:** DEBUG (dev only), INFO, WARN, ERROR

### Analytics
- **User behavior:** Track key actions (signup, upload, export)
- **Funnel analysis:** Signup → Upload → Pro conversion
- **Retention:** Weekly/monthly active users
- **Revenue metrics:** MRR, churn rate, ARPU

---

## Cost Estimates

### Infrastructure (First 100 Users)

**Fixed Costs:**
- Vercel: **$0/month** (Hobby plan)
- Database (Neon): **$0/month** (Free tier: 500MB)
- QStash: **$0/month** (Free tier: 500 jobs/day)
- Resend: **$0/month** (Free tier: 100 emails/day)
- Sentry: **$0/month** (Free tier)
- **Subtotal: $0/month**

**Variable Costs:**
- S3 storage: **$0.023/GB/month** (~$1-2/month for 100 users)
- CloudFront bandwidth: **$0.085/GB** (~$3-5/month)
- Claude API: **~$0.10/image**
  - 100 users × 25 images = 2,500 images
  - 2,500 × $0.10 = **$250/month**
- **Subtotal: ~$255-260/month**

**Total: ~$260/month** for first 100 users

### Revenue (Conservative Conversion)
- 100 users, 3% conversion = 3 paid users
- 3 × $29/month = **$87 MRR**
- **Net: -$173/month**

Break-even at ~10-12 paid users ($290-350 MRR)

### Cost Optimization Strategies
1. **Batch Claude API calls** - Process multiple images per request
2. **Cache similar images** - Reuse metadata for similar images
3. **Optimize prompts** - Shorter prompts = lower cost
4. **Lazy generation** - Only generate metadata when viewed
5. **Tiered AI models** - Use cheaper models for simple images

---

## Development Timeline

**Estimated: 5 weeks (solo developer, 20-30 hours/week)**

### Week 1: Foundation
- [ ] Project setup (Next.js, Prisma, Tailwind, shadcn/ui)
- [ ] Database schema design and migration
- [ ] NextAuth configuration (email/password + magic link)
- [ ] Basic UI shell (layouts, navigation, authentication pages)
- [ ] Environment setup (local + Vercel)

**Deliverable:** Working authentication flow

### Week 2: Collections & Upload
- [ ] Collection CRUD (create, list, view, delete)
- [ ] Image upload UI (drag-and-drop with react-dropzone)
- [ ] S3 integration (upload with compression)
- [ ] Image model and database storage
- [ ] Basic image grid display

**Deliverable:** Users can create collections and upload images

### Week 3: AI Integration
- [ ] Claude API integration
- [ ] Metadata generation prompts
- [ ] Color extraction with node-vibrant/Sharp
- [ ] QStash setup and job queuing
- [ ] Background job handler for image processing
- [ ] Status polling on client

**Deliverable:** Images automatically get metadata after upload

### Week 4: Metadata & Export
- [ ] Metadata display UI
- [ ] Metadata editing forms
- [ ] Regenerate metadata button
- [ ] JSON export functionality
- [ ] Copy to clipboard
- [ ] Usage tracking (images per billing period)

**Deliverable:** Full metadata workflow complete

### Week 5: Billing & Polish
- [ ] Stripe integration
- [ ] Subscription checkout flow
- [ ] Usage limits enforcement
- [ ] Upgrade prompts
- [ ] Customer portal link
- [ ] Error handling and loading states
- [ ] Responsive design refinements
- [ ] Performance optimization
- [ ] Deploy to production
- [ ] DNS and domain setup

**Deliverable:** Production-ready MVP

---

## Testing Strategy

### Manual Testing (MVP)
- Core user flows (signup → upload → edit → export)
- Edge cases (file size limits, unsupported formats, errors)
- Different browsers (Chrome, Firefox, Safari)
- Mobile responsive testing

### Automated Testing (Post-MVP)
- **Unit tests:** Utility functions, validation schemas
- **Integration tests:** API routes
- **E2E tests:** Critical paths (signup, upload, purchase)
- **Visual regression:** Component changes don't break UI

---

## Launch Checklist

### Pre-Launch
- [ ] Legal pages (Privacy Policy, Terms of Service)
- [ ] Email templates (welcome, magic link, billing)
- [ ] Error pages (404, 500)
- [ ] SEO meta tags (title, description, OG images)
- [ ] Favicon and app icons
- [ ] Analytics setup (Plausible/PostHog)
- [ ] Error tracking (Sentry)
- [ ] Domain and SSL
- [ ] Stripe test mode → live mode
- [ ] Security audit (OWASP top 10)
- [ ] Load testing (basic)

### Launch Day
- [ ] Deploy to production
- [ ] Smoke test critical flows
- [ ] Monitor error rates
- [ ] Product Hunt launch post
- [ ] Twitter/X announcement
- [ ] Post in relevant communities (r/SideProject, r/webdev)
- [ ] Email beta users (if any)

### Post-Launch (Week 1)
- [ ] Monitor usage patterns
- [ ] Collect user feedback
- [ ] Fix critical bugs immediately
- [ ] Iterate on onboarding based on drop-off points
- [ ] Write case studies/examples

---

## Future Phases (Post-MVP)

### Phase 2: BYOK (Bring Your Own Keys)
- User-provided Claude API keys
- User-provided AWS credentials
- Lower pricing tier for BYOK users
- Key validation and testing flow

### Phase 3: Team Collaboration
- Invite team members to collections
- Role-based access control
- Shared collections
- Activity log

### Phase 4: API Access
- REST API with API key authentication
- Rate limiting per API key
- Comprehensive API documentation
- Webhook support for job completion

### Phase 5: MCP Server
- Model Context Protocol server
- Chat-based collection management
- Natural language image upload
- Integration with Claude Code, Cursor

### Phase 6: Advanced Features
- Batch operations (bulk edit, bulk delete)
- Image search within collections
- Collection templates (starter kits)
- Style-based image recommendations
- Integration with design tools (Figma plugin)
- White-label API for platforms

---

## Success Metrics

### Product Metrics
- **Signups:** New users per week
- **Activation:** % of users who upload at least 1 image
- **Engagement:** Images uploaded per user per month
- **Retention:** % of users active after 7/30 days
- **Conversion:** % of free users who upgrade to Pro

### Business Metrics
- **MRR:** Monthly Recurring Revenue
- **Churn Rate:** % of paid users who cancel per month
- **ARPU:** Average Revenue Per User
- **CAC:** Customer Acquisition Cost
- **LTV:CAC Ratio:** Lifetime Value to Acquisition Cost

### Technical Metrics
- **Uptime:** Target 99.9%
- **API response time:** P95 < 500ms
- **Image processing time:** P95 < 30 seconds
- **Error rate:** < 0.1%
- **Build time:** < 3 minutes

### Key Targets (Month 12)
- 700 free users
- 29 paid users
- $1,332 MRR
- 3% free-to-paid conversion
- 95%+ user satisfaction (NPS)

---

## Risk Assessment

### Technical Risks
| Risk | Impact | Probability | Mitigation |
|------|---------|-------------|------------|
| Claude API rate limits | High | Medium | Implement queuing, batch requests, cache results |
| S3 costs spike | Medium | Low | Set billing alerts, implement storage limits |
| QStash downtime | Medium | Low | Add fallback polling mechanism |
| Database limits exceeded | High | Low | Monitor usage, upgrade tier proactively |

### Business Risks
| Risk | Impact | Probability | Mitigation |
|------|---------|-------------|------------|
| Low conversion rate | High | Medium | Improve onboarding, add testimonials, case studies |
| High churn | High | Low | Collect feedback, improve value prop |
| Competition | Medium | Medium | Focus on UX and quality, build community |
| Slow growth | Medium | High | Content marketing, partnerships, community building |

### Operational Risks
| Risk | Impact | Probability | Mitigation |
|------|---------|-------------|------------|
| Solo founder burnout | High | Medium | Set realistic timeline, focus on MVP, consider co-founder |
| Security breach | High | Low | Security audit, implement best practices, bug bounty |
| Legal issues | High | Low | Clear ToS/Privacy Policy, GDPR compliance |

---

## Conclusion

This architecture document outlines a pragmatic, scalable approach to building an image metadata generation SaaS. The tech stack prioritizes:

1. **Speed to market:** Monolithic Next.js architecture minimizes complexity
2. **Cost efficiency:** Serverless architecture with generous free tiers
3. **Developer experience:** TypeScript, Prisma, modern tooling
4. **Future flexibility:** Can scale and separate concerns when needed

The MVP scope is intentionally focused on core value: **generating high-quality metadata that improves AI-assisted web design**. Post-MVP phases can expand based on validated user needs and feedback.

**Next Steps:**
1. Set up development environment
2. Initialize Next.js project with chosen tech stack
3. Begin Week 1 development tasks
4. Launch MVP within 5 weeks
5. Iterate based on user feedback

---

**Document Version:** 1.0  
**Last Updated:** 2024-11-06  
**Author:** Architecture Planning Session  
**Status:** Ready for Implementation
