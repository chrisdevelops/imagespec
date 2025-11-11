# Quota Type Definitions

## Description
Define TypeScript types for quota management including quota info, reservation results, and subscription tier features.

## Dependencies
- [ ] 01-infrastructure-database/10-type-definitions-database.md

## Acceptance Criteria
- [ ] QuotaInfo type defined
- [ ] ReservationResult type defined
- [ ] SubscriptionTierFeatures type defined
- [ ] SubscriptionTier type extended with features
- [ ] API request/response types
- [ ] Zod schemas for validation
- [ ] All types exported from `src/lib/types/quota.ts`

## Technical Notes
- Create types file: `src/lib/types/quota.ts`
- Core types:
  ```typescript
  import { Database } from './database';

  export type SubscriptionTier = Database['public']['Tables']['subscription_tiers']['Row'];

  export interface SubscriptionTierFeatures {
    max_bulk_upload: number;
    api_access: boolean;
    priority_processing?: boolean;
    custom_integrations?: boolean;
    support: 'community' | 'email' | 'dedicated';
  }

  export interface QuotaInfo {
    used: number;
    quota_limit: number; // -1 for unlimited
    remaining: number; // -1 for unlimited
    tier: string;
    features: SubscriptionTierFeatures;
  }

  export interface ReservationResult {
    success: boolean;
    used: number;
    quota_limit: number;
    remaining: number;
  }

  export interface UsageStats {
    images_used_this_period: number;
    images_per_period: number;
    period_start: Date;
    period_end: Date;
    days_remaining: number;
  }
  ```
- API types:
  ```typescript
  export interface CheckQuotaResponse {
    has_quota: boolean;
    used: number;
    quota_limit: number;
    remaining: number;
  }

  export interface ReserveQuotaRequest {
    count: number;
  }

  export interface ReserveQuotaResponse extends ReservationResult {
    message?: string;
  }

  export interface RollbackQuotaRequest {
    count: number;
  }
  ```
- Zod schemas:
  ```typescript
  import { z } from 'zod';

  export const subscriptionTierFeaturesSchema = z.object({
    max_bulk_upload: z.number().int().positive(),
    api_access: z.boolean(),
    priority_processing: z.boolean().optional(),
    custom_integrations: z.boolean().optional(),
    support: z.enum(['community', 'email', 'dedicated'])
  });

  export const reserveQuotaRequestSchema = z.object({
    count: z.number().int().positive().max(100)
  });
  ```
- Type guards:
  ```typescript
  export function isUnlimitedQuota(quota: QuotaInfo): boolean {
    return quota.quota_limit === -1;
  }

  export function hasQuotaRemaining(quota: QuotaInfo, count: number = 1): boolean {
    if (isUnlimitedQuota(quota)) return true;
    return quota.remaining >= count;
  }

  export function getQuotaPercentageUsed(quota: QuotaInfo): number {
    if (isUnlimitedQuota(quota)) return 0;
    return (quota.used / quota.quota_limit) * 100;
  }
  ```
- Re-export from main types:
  ```typescript
  // src/lib/types/index.ts
  export * from './quota';
  ```
- **GOTCHA**: Handle -1 (unlimited) specially in all calculations
- **GOTCHA**: Features JSONB is untyped in DB - validate at runtime

## Architecture Reference
- CLAUDE.md: Types in Separate Files
- Database schema: subscription_tiers.features JSONB
- ARCHITECTURE.md Section 6: Quota types
