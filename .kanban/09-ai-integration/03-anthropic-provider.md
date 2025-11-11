# Anthropic Provider Implementation

## Description
Implement Anthropic Claude Vision provider as alternative/fallback.

## Dependencies
- [ ] 09-ai-integration/01-ai-provider-interface.md

## Acceptance Criteria
- [ ] Anthropic SDK installed
- [ ] Anthropic provider implements AiProvider
- [ ] Uses Claude 3 Sonnet or Opus
- [ ] Same prompt structure as OpenAI
- [ ] Rate limiting
- [ ] Retry logic
- [ ] Token tracking
- [ ] Error handling

## Technical Notes
- Install: `npm install @anthropic-ai/sdk`
- Create: `src/lib/ai/providers/anthropic.ts`
- Use Claude 3 for vision capabilities
- Same AiResponse format as OpenAI
- **GOTCHA**: Different pricing model
- Can be primary or fallback provider

## Architecture Reference
- ARCHITECTURE.md Section 7: Anthropic Provider Implementation
