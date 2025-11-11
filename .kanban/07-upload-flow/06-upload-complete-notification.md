# Upload Complete Notification

## Description
Implement notifications and UI updates when uploads complete successfully, including navigation to view uploaded images.

## Dependencies
- [ ] 07-upload-flow/01-upload-queue-manager.md

## Acceptance Criteria
- [ ] Toast notification on single upload completion
- [ ] Summary notification for bulk uploads
- [ ] Shows count of successful uploads
- [ ] "View images" action button
- [ ] Updates collection view in real-time
- [ ] Confetti/celebration animation (optional, for first upload)
- [ ] Sound notification (optional, user preference)
- [ ] Processing status notification
- [ ] Metadata generation notification
- [ ] Browser notification for background uploads

## Technical Notes
- Create notification utility: `src/lib/upload/notifications.ts`
- Single upload completion:
  ```typescript
  function notifySingleUploadComplete(image: { id: string; name: string }) {
    toast.success(
      <div className="flex items-center gap-2">
        <CheckCircle2 className="h-5 w-5" />
        <div>
          <p className="font-medium">Upload complete!</p>
          <p className="text-sm text-muted-foreground">{image.name}</p>
        </div>
      </div>,
      {
        action: {
          label: 'View',
          onClick: () => router.push(`/images/${image.id}`)
        }
      }
    );
  }
  ```
- Bulk upload completion:
  ```typescript
  function notifyBulkUploadComplete(results: UploadResults) {
    const message = results.failed.length === 0
      ? `All ${results.succeeded} images uploaded successfully!`
      : `${results.succeeded} succeeded, ${results.failed.length} failed`;

    toast.success(
      <div>
        <p className="font-medium">{message}</p>
        {results.failed.length > 0 && (
          <p className="text-sm">Processing will begin shortly</p>
        )}
      </div>,
      {
        duration: 5000,
        action: {
          label: 'View Collection',
          onClick: () => router.push(`/collections/${collectionId}`)
        }
      }
    );
  }
  ```
- Processing status updates (via Realtime):
  ```typescript
  function setupProcessingNotifications(imageIds: string[]) {
    const channel = supabase
      .channel('upload-processing')
      .on('postgres_changes', {
        event: 'UPDATE',
        schema: 'public',
        table: 'images',
        filter: `id=in.(${imageIds.join(',')})`
      }, (payload) => {
        const image = payload.new;

        if (image.status === 'completed') {
          toast.success(`Metadata generated for ${image.original_name}`);
        } else if (image.status === 'failed') {
          toast.error(`Processing failed for ${image.original_name}`);
        }
      })
      .subscribe();

    return () => supabase.removeChannel(channel);
  }
  ```
- First upload celebration:
  ```typescript
  import confetti from 'canvas-confetti';

  async function checkFirstUpload(userId: string) {
    const { count } = await supabase
      .from('images')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', userId);

    return count === 1; // First upload
  }

  function celebrateFirstUpload() {
    confetti({
      particleCount: 100,
      spread: 70,
      origin: { y: 0.6 }
    });

    toast.success(
      "🎉 Congratulations on your first upload!",
      { duration: 5000 }
    );
  }
  ```
- Browser notifications (optional):
  ```typescript
  async function sendBrowserNotification(title: string, body: string) {
    if ('Notification' in window && Notification.permission === 'granted') {
      new Notification(title, {
        body,
        icon: '/icon.png',
        badge: '/badge.png'
      });
    }
  }

  // Request permission on first load
  async function requestNotificationPermission() {
    if ('Notification' in window && Notification.permission === 'default') {
      await Notification.requestPermission();
    }
  }
  ```
- Real-time collection update:
  ```typescript
  // Refresh collection images list
  mutate(`/api/collections/${collectionId}`);

  // Or use Supabase Realtime to update automatically
  ```
- **GOTCHA**: Don't spam with notifications for every image in bulk upload
- **GOTCHA**: Use toast.promise for upload in progress
- Install canvas-confetti: `npm install canvas-confetti` (optional)

## Architecture Reference
- ARCHITECTURE.md Section 8: Upload Complete Notification
- User experience: provide feedback on successful uploads
