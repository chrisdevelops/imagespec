# AI Provider Interface

## Description
Define AiProvider interface for multi-provider support (OpenAI, Anthropic, others).

## Dependencies
- None (foundation)

## Acceptance Criteria
- [ ] AiProvider interface defined
- [ ] analyzeImage method signature
- [ ] AiRequest type defined
- [ ] AiResponse type defined
- [ ] Provider-specific config support
- [ ] Error types defined
- [ ] Types exported from `src/lib/types/ai.ts`

## Technical Notes
- Create interface: `src/lib/ai/providers/types.ts`
  ```typescript
  export interface AiProvider {
    name: string;
    analyzeImage(params: {
      imageUrl: string;
      width: number;
      height: number;
      prompt?: string;
    }): Promise<AiResponse>;
  }

  export interface AiResponse {
    description: string;
    altText: string;
    keywords: string[];
    focalPoint: string;
    styleTags: string[];
    mood: string[];
    suggestedUseCases: string[];
    textOverlaySafe: boolean;
    safeTextZones: string[];
    rawResponse: string; // for storage
  }
  ```
- All providers must implement this interface
- Responses normalized to common format

## Architecture Reference
- ARCHITECTURE.md Section 7: AI Adapter design
