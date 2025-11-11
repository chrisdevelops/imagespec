# Quota UI Components

## Description
Create reusable UI components for displaying quota usage, limits, and upgrade prompts throughout the application.

## Dependencies
- [ ] 06-quota-management/02-quota-checking-api.md

## Acceptance Criteria
- [ ] UsageBar component created (progress bar showing quota used/remaining)
- [ ] QuotaDisplay component (shows used/total/remaining)
- [ ] UpgradePrompt component (CTA when approaching limit)
- [ ] QuotaExceededModal component (shown when quota exhausted)
- [ ] BulkUploadLimitNotice component (shows tier-based bulk limits)
- [ ] All components responsive and accessible
- [ ] Real-time quota updates
- [ ] Visual indicators for quota status (healthy/warning/critical)

## Technical Notes
- Create components in `src/components/quota/`
- **UsageBar Component:**
  ```tsx
  interface UsageBarProps {
    used: number;
    limit: number;
    showUpgrade?: boolean;
  }

  export function UsageBar({ used, limit, showUpgrade }: UsageBarProps) {
    const percentage = limit === -1 ? 0 : (used / limit) * 100;
    const status = percentage > 90 ? 'critical' : percentage > 75 ? 'warning' : 'healthy';

    return (
      <div>
        <Progress value={percentage} className={status} />
        <p>{used} of {limit === -1 ? '∞' : limit} images used</p>
        {showUpgrade && percentage > 75 && <UpgradePrompt />}
      </div>
    );
  }
  ```
- **QuotaDisplay Component:**
  - Shows numeric display of quota
  - Color-coded based on remaining
  - Green: >25% remaining
  - Yellow: 10-25% remaining
  - Red: <10% remaining
- **UpgradePrompt Component:**
  - Call-to-action button
  - "Upgrade to Pro for 1,000 images/month"
  - Links to pricing page
  - Shown when quota >75% used
- **QuotaExceededModal:**
  - Blocks upload action
  - Clear message: "You've reached your upload limit"
  - Shows current plan limits
  - Upgrade button prominent
  - Option to delete old images
- **BulkUploadLimitNotice:**
  - Shown in upload UI
  - "Free: 1 image at a time"
  - "Pro: up to 20 images at once"
  - Inline with upload button
- Fetch quota in components:
  ```tsx
  const { data: quota } = useSWR('/api/usage', fetcher);
  ```
- **GOTCHA**: Handle unlimited quota (quota_limit = -1) specially
- **GOTCHA**: Update in real-time after uploads
- Use shadcn Progress component for bars

## Architecture Reference
- ARCHITECTURE.md Section 6: Quota UI Components
- User story: UI should show how many uploads are allowed
