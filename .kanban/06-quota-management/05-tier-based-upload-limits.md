# Tier-Based Upload Limits

## Description
Implement and enforce tier-based upload limits for bulk uploads, reading max_bulk_upload from subscription features.

## Dependencies
- [ ] 01-infrastructure-database/05-seed-subscription-tiers.md
- [ ] 06-quota-management/02-quota-checking-api.md

## Acceptance Criteria
- [ ] Read max_bulk_upload from subscription_tiers.features JSONB
- [ ] Enforce limit in upload UI (file selection)
- [ ] Free tier: max 1 file at a time
- [ ] Pro tier: max 20 files at a time (configurable)
- [ ] Enterprise tier: configurable limit (default 50 or unlimited)
- [ ] Clear error message when limit exceeded
- [ ] UI shows tier limit before file selection
- [ ] Upgrade prompt when hitting free tier limit
- [ ] Test with different tiers

## Technical Notes
- Fetch user's tier and features:
  ```typescript
  const { data: user } = await supabase
    .from('users')
    .select('subscription_tier, subscription_tiers(features)')
    .single();

  const maxBulkUpload = user.subscription_tiers.features.max_bulk_upload;
  ```
- Enforce in file selection:
  ```tsx
  const handleFileSelect = (files: File[]) => {
    if (files.length > maxBulkUpload) {
      toast.error(`Your ${tier} plan allows up to ${maxBulkUpload} images at once. Please upgrade for bulk uploads.`);
      return;
    }
    // Proceed with upload
  };
  ```
- Display limit in UI:
  ```tsx
  <p className="text-sm text-muted-foreground">
    {tier === 'free'
      ? 'Upload 1 image at a time with Free plan'
      : `Upload up to ${maxBulkUpload} images at once with ${tier} plan`
    }
  </p>
  ```
- File input configuration:
  ```tsx
  <input
    type="file"
    multiple={maxBulkUpload > 1}
    accept="image/*"
    onChange={handleFileSelect}
  />
  ```
- Dropzone configuration:
  ```tsx
  const { getRootProps } = useDropzone({
    maxFiles: maxBulkUpload,
    onDropRejected: (rejections) => {
      if (rejections.some(r => r.errors.find(e => e.code === 'too-many-files'))) {
        toast.error(`Maximum ${maxBulkUpload} files allowed`);
      }
    }
  });
  ```
- Upgrade prompt for free users:
  ```tsx
  {tier === 'free' && (
    <Alert>
      <AlertTitle>Upgrade to Pro</AlertTitle>
      <AlertDescription>
        Upload up to 20 images at once with Pro plan.
        <Button variant="link">Upgrade Now</Button>
      </AlertDescription>
    </Alert>
  )}
  ```
- **GOTCHA**: Bulk limit is separate from total quota
  - Bulk limit: how many at ONCE
  - Quota: how many total per period
  - Check both before upload
- **TODO**: Make limits configurable via Supabase without migration

## Architecture Reference
- ARCHITECTURE.md Section 4: Data model notes (features JSONB)
- ARCHITECTURE.md Section 8: Upload flow (bulk upload limits)
- User story: free=1 at time, pro=20 at time, UI shows allowed count
