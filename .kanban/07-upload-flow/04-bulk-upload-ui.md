# Bulk Upload UI

## Description
Create comprehensive bulk upload interface showing queue status, overall progress, and individual file progress.

## Dependencies
- [ ] 07-upload-flow/01-upload-queue-manager.md
- [ ] 07-upload-flow/02-file-dropzone-component.md
- [ ] 07-upload-flow/03-upload-progress-bar.md

## Acceptance Criteria
- [ ] BulkUploadUI component shows all queued uploads
- [ ] Overall progress summary (X of Y completed)
- [ ] Individual progress bars for each file
- [ ] Pause/resume all uploads button
- [ ] Cancel all uploads button
- [ ] Clear completed uploads button
- [ ] Collapsible/expandable view
- [ ] Shows success count and failure count
- [ ] Auto-collapses after all uploads complete
- [ ] Mobile-responsive layout

## Technical Notes
- Create component: `src/components/upload/BulkUploadUI.tsx`
- Component structure:
  ```tsx
  interface BulkUploadUIProps {
    uploads: UploadItem[];
    onPauseAll?: () => void;
    onResumeAll?: () => void;
    onCancelAll?: () => void;
    onClearCompleted?: () => void;
  }

  export function BulkUploadUI({
    uploads,
    onPauseAll,
    onResumeAll,
    onCancelAll,
    onClearCompleted
  }: BulkUploadUIProps) {
    const [isExpanded, setIsExpanded] = useState(true);

    const stats = useMemo(() => {
      const total = uploads.length;
      const completed = uploads.filter(u => u.status === 'completed').length;
      const failed = uploads.filter(u => u.status === 'failed').length;
      const uploading = uploads.filter(u => u.status === 'uploading').length;
      const overallProgress = total > 0 ? (completed / total) * 100 : 0;

      return { total, completed, failed, uploading, overallProgress };
    }, [uploads]);

    return (
      <Card className="fixed bottom-4 right-4 w-96 max-h-[80vh] overflow-hidden">
        {/* Header */}
        <div className="flex items-center justify-between p-4 border-b">
          <div className="flex items-center gap-2">
            <Upload className="h-5 w-5" />
            <div>
              <h3 className="font-medium">Uploading {stats.total} files</h3>
              <p className="text-xs text-muted-foreground">
                {stats.completed} completed, {stats.failed} failed
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2">
            <Button
              size="sm"
              variant="ghost"
              onClick={() => setIsExpanded(!isExpanded)}
            >
              {isExpanded ? <ChevronDown /> : <ChevronUp />}
            </Button>
          </div>
        </div>

        {/* Overall progress */}
        <div className="p-4 border-b">
          <Progress value={stats.overallProgress} />
          <p className="text-xs text-center mt-2">
            {Math.round(stats.overallProgress)}% complete
          </p>
        </div>

        {/* Actions */}
        <div className="flex gap-2 p-4 border-b">
          {stats.uploading > 0 && (
            <Button size="sm" variant="outline" onClick={onPauseAll}>
              <Pause className="h-4 w-4 mr-2" />
              Pause All
            </Button>
          )}
          <Button size="sm" variant="outline" onClick={onCancelAll}>
            <X className="h-4 w-4 mr-2" />
            Cancel All
          </Button>
          {stats.completed > 0 && (
            <Button size="sm" variant="outline" onClick={onClearCompleted}>
              Clear Completed
            </Button>
          )}
        </div>

        {/* Individual uploads */}
        {isExpanded && (
          <ScrollArea className="max-h-96">
            <div className="p-4 space-y-4">
              {uploads.map(upload => (
                <UploadProgressBar
                  key={upload.id}
                  file={upload.file}
                  progress={upload.progress}
                  status={upload.status}
                  speed={upload.speed}
                  eta={upload.eta}
                  onCancel={() => upload.abort()}
                  onRetry={() => upload.retry()}
                />
              ))}
            </div>
          </ScrollArea>
        )}
      </Card>
    );
  }
  ```
- Auto-collapse after completion:
  ```tsx
  useEffect(() => {
    if (stats.completed === stats.total && stats.total > 0) {
      const timer = setTimeout(() => {
        setIsExpanded(false);
      }, 3000); // Collapse after 3 seconds
      return () => clearTimeout(timer);
    }
  }, [stats]);
  ```
- Pause/resume implementation:
  ```tsx
  const handlePauseAll = () => {
    uploads.forEach(upload => {
      if (upload.status === 'uploading') {
        upload.pause();
      }
    });
  };

  const handleResumeAll = () => {
    uploads.forEach(upload => {
      if (upload.status === 'paused') {
        upload.resume();
      }
    });
  };
  ```
- **GOTCHA**: Fixed position overlay (doesn't block UI)
- **GOTCHA**: Use z-index to stay on top
- **GOTCHA**: Persist upload state across page navigation (optional)
- Use shadcn ScrollArea for file list

## Architecture Reference
- ARCHITECTURE.md Section 8: Upload flow
- User story: show progress for bulk uploads
