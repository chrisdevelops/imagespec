# Upload Progress Bar

## Description
Create individual upload progress bar component showing real-time progress, speed, and ETA for each file.

## Dependencies
- [ ] 03-storage-setup/04-client-side-upload-implementation.md

## Acceptance Criteria
- [ ] UploadProgressBar component created
- [ ] Shows file name and thumbnail
- [ ] Real-time progress percentage (0-100%)
- [ ] Upload speed display (MB/s or KB/s)
- [ ] Estimated time remaining (ETA)
- [ ] Status indicators (uploading/completed/failed)
- [ ] Cancel button (aborts upload)
- [ ] Retry button for failed uploads
- [ ] Smooth progress animation
- [ ] Handles edge cases (instant upload, stalled upload)

## Technical Notes
- Create component: `src/components/upload/UploadProgressBar.tsx`
- Component structure:
  ```tsx
  interface UploadProgressBarProps {
    file: File;
    progress: number; // 0-100
    status: 'uploading' | 'completed' | 'failed' | 'cancelled';
    speed?: number; // bytes per second
    eta?: number; // seconds
    onCancel?: () => void;
    onRetry?: () => void;
  }

  export function UploadProgressBar({
    file,
    progress,
    status,
    speed,
    eta,
    onCancel,
    onRetry
  }: UploadProgressBarProps) {
    return (
      <div className="space-y-2 p-4 border rounded">
        <div className="flex items-center gap-3">
          {/* Thumbnail */}
          <img src={preview} className="w-12 h-12 rounded object-cover" />

          {/* File info */}
          <div className="flex-1 min-w-0">
            <p className="font-medium truncate">{file.name}</p>
            <div className="flex gap-3 text-xs text-muted-foreground">
              <span>{formatFileSize(file.size)}</span>
              {speed && <span>{formatSpeed(speed)}</span>}
              {eta && <span>ETA: {formatETA(eta)}</span>}
            </div>
          </div>

          {/* Status icon */}
          <div>
            {status === 'uploading' && <Loader2 className="animate-spin" />}
            {status === 'completed' && <CheckCircle2 className="text-green-500" />}
            {status === 'failed' && <XCircle className="text-red-500" />}
          </div>

          {/* Actions */}
          <div>
            {status === 'uploading' && onCancel && (
              <Button size="sm" variant="ghost" onClick={onCancel}>
                <X className="h-4 w-4" />
              </Button>
            )}
            {status === 'failed' && onRetry && (
              <Button size="sm" variant="ghost" onClick={onRetry}>
                <RotateCw className="h-4 w-4" />
              </Button>
            )}
          </div>
        </div>

        {/* Progress bar */}
        <Progress value={progress} className={getProgressColor(status)} />

        {/* Status text */}
        <p className="text-xs text-center">
          {status === 'uploading' && `${Math.round(progress)}%`}
          {status === 'completed' && 'Upload complete'}
          {status === 'failed' && 'Upload failed'}
          {status === 'cancelled' && 'Upload cancelled'}
        </p>
      </div>
    );
  }
  ```
- Utility functions:
  ```typescript
  function formatFileSize(bytes: number): string {
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  }

  function formatSpeed(bytesPerSecond: number): string {
    if (bytesPerSecond < 1024) return `${bytesPerSecond} B/s`;
    if (bytesPerSecond < 1024 * 1024) return `${(bytesPerSecond / 1024).toFixed(1)} KB/s`;
    return `${(bytesPerSecond / (1024 * 1024)).toFixed(1)} MB/s`;
  }

  function formatETA(seconds: number): string {
    if (seconds < 60) return `${Math.round(seconds)}s`;
    const minutes = Math.floor(seconds / 60);
    const secs = Math.round(seconds % 60);
    return `${minutes}m ${secs}s`;
  }
  ```
- Calculate speed and ETA:
  ```typescript
  const [uploadStart, setUploadStart] = useState(Date.now());
  const [lastProgress, setLastProgress] = useState({ bytes: 0, time: Date.now() });

  const calculateSpeed = (loaded: number) => {
    const now = Date.now();
    const timeDiff = (now - lastProgress.time) / 1000; // seconds
    const bytesDiff = loaded - lastProgress.bytes;
    const speed = bytesDiff / timeDiff; // bytes per second
    setLastProgress({ bytes: loaded, time: now });
    return speed;
  };

  const calculateETA = (loaded: number, total: number, speed: number) => {
    const remaining = total - loaded;
    return remaining / speed; // seconds
  };
  ```
- **GOTCHA**: Handle division by zero in ETA calculation
- **GOTCHA**: Smooth progress updates (don't update too frequently)
- Use shadcn Progress component with status-based colors

## Architecture Reference
- ARCHITECTURE.md Section 4: Upload Progress
- ARCHITECTURE.md Section 8: Client UX flows (upload progress)
