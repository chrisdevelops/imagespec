# Images Type Definitions

## Description
Define comprehensive TypeScript types for all image-related data structures, API requests/responses, and component props.

## Dependencies
- [ ] 01-infrastructure-database/10-type-definitions-database.md

## Acceptance Criteria
- [ ] Image type defined from database schema
- [ ] ImageMetadata type defined from database schema
- [ ] ImageWithMetadata composite type
- [ ] ImageUploadRequest/Response types
- [ ] ImageStatus enum
- [ ] ImageOrientation enum
- [ ] All component prop interfaces
- [ ] Zod schemas for validation
- [ ] All types exported from `src/lib/types/image.ts`
- [ ] Documentation for complex types

## Technical Notes
- Create types file: `src/lib/types/image.ts`
- Base types from database:
  ```typescript
  import { Database } from './database';

  export type Image = Database['public']['Tables']['images']['Row'];
  export type ImageMetadata = Database['public']['Tables']['image_metadata']['Row'];

  export interface ImageWithMetadata extends Image {
    image_metadata?: ImageMetadata;
  }

  export enum ImageStatus {
    PROCESSING = 'processing',
    COMPLETED = 'completed',
    FAILED = 'failed'
  }

  export enum ImageOrientation {
    LANDSCAPE = 'landscape',
    PORTRAIT = 'portrait',
    SQUARE = 'square'
  }
  ```
- API types:
  ```typescript
  export interface ImageUploadRequest {
    filename: string;
    contentType: string;
    size: number;
    collectionId: string;
  }

  export interface ImageUploadResponse {
    uploadUrl: string;
    imageId: string;
    s3Key: string;
  }

  export interface ImageCompleteRequest {
    imageId: string;
    s3Key: string;
    fileSize: number;
    mimeType: string;
  }

  export interface ImageUpdateRequest {
    metadata: Partial<ImageMetadata>;
  }
  ```
- Component prop types:
  ```typescript
  export interface ImageCardProps {
    image: ImageWithMetadata;
    onEdit?: () => void;
    onDelete?: () => void;
    onClick?: () => void;
  }

  export interface MetadataDisplayProps {
    metadata: ImageMetadata;
    imageUrl?: string;
    compact?: boolean;
  }

  export interface MetadataEditorProps {
    imageId: string;
    metadata: ImageMetadata;
    onSave: (metadata: ImageMetadata) => Promise<void>;
    onCancel: () => void;
  }
  ```
- Zod validation schemas:
  ```typescript
  import { z } from 'zod';

  export const imageUploadRequestSchema = z.object({
    filename: z.string().min(1),
    contentType: z.string().startsWith('image/'),
    size: z.number().max(10485760), // 10MB
    collectionId: z.string().uuid()
  });

  export const metadataUpdateSchema = z.object({
    description: z.string().min(1).optional(),
    alt_text: z.string().min(1).optional(),
    content_keywords: z.array(z.string()).optional(),
    // ... all metadata fields
  });
  ```
- Re-export from main types index:
  ```typescript
  // src/lib/types/index.ts
  export * from './image';
  ```
- **GOTCHA**: Keep in sync with database schema
- **GOTCHA**: Use strict validation for user inputs
- Add JSDoc comments for complex types

## Architecture Reference
- CLAUDE.md: Types in Separate Files principle
- Database schema: images and image_metadata tables
