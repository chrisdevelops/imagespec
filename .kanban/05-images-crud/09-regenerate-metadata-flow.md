# Regenerate Metadata Flow

## Description
Implement functionality to regenerate metadata for an image, re-processing it through the AI pipeline and consuming quota.

## Dependencies
- [ ] 05-images-crud/01-images-api-implementation.md
- [ ] 06-quota-management/02-quota-checking-api.md
- [ ] 08-processing-pipeline/02-job-enqueue-utility.md

## Acceptance Criteria
- [ ] Regenerate button in image detail view
- [ ] Confirmation modal explaining quota consumption
- [ ] Quota check before allowing regeneration
- [ ] Success: image status changes to "processing"
- [ ] Success: old metadata retained until new completes
- [ ] UI updates when processing completes (realtime)
- [ ] Error handling for quota exceeded
- [ ] Error handling for processing failures
- [ ] Disabled if already processing
- [ ] Shows quota cost (1 image from quota)

## Technical Notes
- Add regenerate button in image detail/card
- Confirmation modal content:
  - "Regenerate metadata for this image?"
  - Warning: "This will use 1 of your available uploads"
  - Show remaining quota
  - "Cancel" and "Regenerate" buttons
- Flow:
  1. User clicks "Regenerate"
  2. Show confirmation modal
  3. Check quota via `check_and_reserve_slots(user, 1)`
  4. If quota available:
     - Call POST `/api/images/[id]/regenerate`
     - Set image status to "processing"
     - Enqueue new processing job
     - Show processing indicator
  5. If no quota:
     - Show quota exceeded error
     - Offer upgrade to Pro
- API endpoint implementation:
  ```tsx
  // POST /api/images/[id]/regenerate
  export async function POST(req: Request, { params }) {
    const { imageId } = params;

    // Check quota
    const quota = await checkAndReserveSlots(userId, 1);
    if (!quota.success) {
      return NextResponse.json({ error: 'Quota exceeded' }, { status: 403 });
    }

    // Update status
    await supabase
      .from('images')
      .update({ status: 'processing' })
      .eq('id', imageId);

    // Enqueue job
    await enqueueProcessingJob(imageId);

    return NextResponse.json({ success: true });
  }
  ```
- Subscribe to realtime updates:
  ```tsx
  useEffect(() => {
    const channel = supabase
      .channel('image-status')
      .on('postgres_changes', {
        event: 'UPDATE',
        schema: 'public',
        table: 'images',
        filter: `id=eq.${imageId}`
      }, (payload) => {
        // Update UI with new status/metadata
      })
      .subscribe();
    return () => { supabase.removeChannel(channel); };
  }, [imageId]);
  ```
- **GOTCHA**: Must reserve quota BEFORE enqueuing job
- **GOTCHA**: Rollback quota if job enqueue fails
- **TODO**: Option to regenerate with different AI provider

## Architecture Reference
- ARCHITECTURE.md Section 5: POST /api/images/[id]/regenerate
- User story: click regenerate to request new metadata (consumes quota)
