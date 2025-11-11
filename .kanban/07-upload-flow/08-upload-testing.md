# Upload Testing

## Description
Implement comprehensive tests for upload functionality covering queue management, error handling, retry logic, and UI components.

## Dependencies
- [ ] 07-upload-flow/01-upload-queue-manager.md
- [ ] 07-upload-flow/05-upload-error-handling.md

## Acceptance Criteria
- [ ] Unit tests for UploadQueueManager
- [ ] Unit tests for error classification and retry logic
- [ ] Integration tests for full upload flow
- [ ] Tests for concurrent uploads (5 at once)
- [ ] Tests for quota checking before upload
- [ ] Tests for upload cancellation
- [ ] Tests for retry with exponential backoff
- [ ] Tests for various error scenarios
- [ ] Component tests for upload UI
- [ ] E2E test for complete upload flow
- [ ] All tests passing in CI

## Technical Notes
- Test framework: Jest + React Testing Library
- Create test files:
  - `src/lib/upload/__tests__/UploadQueueManager.test.ts`
  - `src/lib/upload/__tests__/errorHandler.test.ts`
  - `src/components/upload/__tests__/FileDropzone.test.tsx`
- Mock S3 uploads:
  ```typescript
  jest.mock('@/lib/storage/uploadToS3', () => ({
    uploadToS3: jest.fn()
  }));
  ```
- Test queue manager:
  ```typescript
  describe('UploadQueueManager', () => {
    it('should upload files concurrently with max 5 at once', async () => {
      const manager = new UploadQueueManager({ maxConcurrent: 5 });
      const files = Array(10).fill(null).map((_, i) =>
        new File(['content'], `file${i}.jpg`, { type: 'image/jpeg' })
      );

      await manager.addFiles(files);

      expect(manager.activeUploads).toBeLessThanOrEqual(5);
    });

    it('should call quota check before upload', async () => {
      const checkQuota = jest.fn().mockResolvedValue({ success: true });
      const manager = new UploadQueueManager({ checkQuota });

      await manager.addFiles([new File(['test'], 'test.jpg')]);

      expect(checkQuota).toHaveBeenCalledWith(1);
    });

    it('should handle upload cancellation', async () => {
      const manager = new UploadQueueManager();
      const file = new File(['test'], 'test.jpg');

      const uploadPromise = manager.addFiles([file]);
      manager.cancelUpload(file.name);

      await expect(uploadPromise).resolves.toHaveProperty('cancelled', 1);
    });
  });
  ```
- Test error handling:
  ```typescript
  describe('Upload Error Handling', () => {
    it('should classify network errors as retryable', () => {
      const error = new Error('Failed to fetch');
      const classified = classifyUploadError(error);

      expect(classified.type).toBe(UploadErrorType.NETWORK_ERROR);
      expect(classified.retryable).toBe(true);
    });

    it('should retry with exponential backoff', async () => {
      const fn = jest.fn()
        .mockRejectedValueOnce(new Error('Network error'))
        .mockRejectedValueOnce(new Error('Network error'))
        .mockResolvedValueOnce('success');

      const result = await retryWithBackoff(fn, 3);

      expect(result).toBe('success');
      expect(fn).toHaveBeenCalledTimes(3);
    });

    it('should not retry non-retryable errors', async () => {
      const fn = jest.fn().mockRejectedValue({
        retryable: false,
        type: UploadErrorType.QUOTA_EXCEEDED
      });

      await expect(retryWithBackoff(fn, 3)).rejects.toThrow();
      expect(fn).toHaveBeenCalledTimes(1);
    });
  });
  ```
- Test UI components:
  ```typescript
  describe('FileDropzone', () => {
    it('should accept valid image files', () => {
      const onFilesSelected = jest.fn();
      const { getByRole } = render(
        <FileDropzone maxFiles={5} onFilesSelected={onFilesSelected} />
      );

      const file = new File(['test'], 'test.jpg', { type: 'image/jpeg' });
      const input = getByRole('presentation').querySelector('input[type="file"]');

      fireEvent.change(input, { target: { files: [file] } });

      expect(onFilesSelected).toHaveBeenCalledWith([file]);
    });

    it('should reject files exceeding maxFiles limit', () => {
      const { getByText } = render(
        <FileDropzone maxFiles={2} onFilesSelected={() => {}} />
      );

      const files = [
        new File(['1'], '1.jpg'),
        new File(['2'], '2.jpg'),
        new File(['3'], '3.jpg')
      ];

      const input = document.querySelector('input[type="file"]');
      fireEvent.change(input, { target: { files } });

      expect(getByText(/maximum.*2.*files/i)).toBeInTheDocument();
    });
  });
  ```
- Integration test:
  ```typescript
  describe('Upload Flow Integration', () => {
    it('should complete full upload flow', async () => {
      // Mock API responses
      mockFetch('/api/usage', { data: { remaining: 10 } });
      mockFetch('/api/images/preupload', { uploadUrl: 'https://s3...', imageId: '123' });
      mockFetch('/api/images/complete', { success: true });

      const manager = new UploadQueueManager({ collectionId: 'col-123' });
      const file = new File(['test'], 'test.jpg', { type: 'image/jpeg' });

      const result = await manager.addFiles([file]);

      expect(result.succeeded).toBe(1);
      expect(result.failed).toBe(0);
    });
  });
  ```
- E2E test (Playwright or Cypress):
  ```typescript
  test('upload image end-to-end', async ({ page }) => {
    await page.goto('/collections/123');
    await page.click('button:has-text("Upload")');

    const fileInput = page.locator('input[type="file"]');
    await fileInput.setInputFiles('test-image.jpg');

    await expect(page.locator('.upload-progress')).toBeVisible();
    await expect(page.locator('text=Upload complete')).toBeVisible({ timeout: 10000 });
  });
  ```
- **GOTCHA**: Mock S3 uploads in tests (don't hit real S3)
- **GOTCHA**: Test edge cases (0 bytes file, huge file, etc.)

## Architecture Reference
- ARCHITECTURE.md: Testing strategy
- CLAUDE.md: Testing patterns
