# File Dropzone Component

## Description
Create drag-and-drop file upload component with file validation, preview, and tier-based file limits.

## Dependencies
- [ ] 06-quota-management/05-tier-based-upload-limits.md

## Acceptance Criteria
- [ ] FileDropzone component created
- [ ] Drag-and-drop support for files
- [ ] Click to browse files
- [ ] File type validation (images only)
- [ ] File size validation (max 10MB per file)
- [ ] Respects tier-based bulk upload limits
- [ ] Shows file previews after selection
- [ ] Remove file button for each preview
- [ ] Visual feedback during drag (border highlight)
- [ ] Error messages for invalid files
- [ ] Accessible (keyboard navigation)
- [ ] Mobile-responsive

## Technical Notes
- Install react-dropzone: `npm install react-dropzone`
- Create component: `src/components/upload/FileDropzone.tsx`
- Implementation:
  ```tsx
  import { useDropzone } from 'react-dropzone';

  interface FileDropzoneProps {
    maxFiles: number;
    onFilesSelected: (files: File[]) => void;
    disabled?: boolean;
  }

  export function FileDropzone({ maxFiles, onFilesSelected, disabled }: FileDropzoneProps) {
    const { getRootProps, getInputProps, isDragActive, fileRejections } = useDropzone({
      accept: {
        'image/*': ['.png', '.jpg', '.jpeg', '.webp', '.gif']
      },
      maxFiles: maxFiles,
      maxSize: 10485760, // 10MB
      disabled,
      onDrop: (acceptedFiles) => {
        onFilesSelected(acceptedFiles);
      }
    });

    return (
      <div
        {...getRootProps()}
        className={cn(
          "border-2 border-dashed rounded-lg p-8 text-center cursor-pointer transition",
          isDragActive && "border-primary bg-primary/10",
          disabled && "opacity-50 cursor-not-allowed"
        )}
      >
        <input {...getInputProps()} />
        {isDragActive ? (
          <p>Drop files here...</p>
        ) : (
          <div>
            <Upload className="mx-auto h-12 w-12 text-muted-foreground" />
            <p>Drag & drop images here, or click to browse</p>
            <p className="text-sm text-muted-foreground mt-2">
              Max {maxFiles} files, up to 10MB each
            </p>
          </div>
        )}
      </div>
    );
  }
  ```
- File preview component:
  ```tsx
  interface FilePreviewProps {
    file: File;
    onRemove: () => void;
  }

  function FilePreview({ file, onRemove }: FilePreviewProps) {
    const [preview, setPreview] = useState<string>('');

    useEffect(() => {
      const url = URL.createObjectURL(file);
      setPreview(url);
      return () => URL.revokeObjectURL(url);
    }, [file]);

    return (
      <div className="relative">
        <img src={preview} alt={file.name} className="w-20 h-20 object-cover rounded" />
        <button
          onClick={onRemove}
          className="absolute -top-2 -right-2 bg-destructive text-white rounded-full p-1"
        >
          <X className="h-4 w-4" />
        </button>
        <p className="text-xs truncate mt-1">{file.name}</p>
      </div>
    );
  }
  ```
- Error handling for rejections:
  ```tsx
  useEffect(() => {
    if (fileRejections.length > 0) {
      fileRejections.forEach(({ file, errors }) => {
        errors.forEach(error => {
          if (error.code === 'file-too-large') {
            toast.error(`${file.name} is too large (max 10MB)`);
          } else if (error.code === 'file-invalid-type') {
            toast.error(`${file.name} is not a valid image`);
          } else if (error.code === 'too-many-files') {
            toast.error(`Maximum ${maxFiles} files allowed`);
          }
        });
      });
    }
  }, [fileRejections]);
  ```
- **GOTCHA**: Clean up object URLs to prevent memory leaks
- **GOTCHA**: Disable dropzone during upload
- **GOTCHA**: Show clear file size limits

## Architecture Reference
- ARCHITECTURE.md Section 8: Upload flow (client UX)
- User story: drag-and-drop or browse to select files
