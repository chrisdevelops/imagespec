# Onboarding Experience

## Description
Create a welcoming onboarding flow for new users showing plan information, usage limits, and guiding them to upload their first image.

## Dependencies
- [ ] 02-authentication/02-signup-flow.md
- [ ] 04-collections-crud/01-collections-api-implementation.md

## Acceptance Criteria
- [ ] Welcome modal shows after first signup
- [ ] Display plan information (Free tier limits)
- [ ] Show usage quota (100 images/month for free)
- [ ] "Create your first collection" CTA
- [ ] "Upload your first image" tutorial
- [ ] Tooltip hints for key features
- [ ] Onboarding state tracked (not shown again)
- [ ] Skip onboarding option available
- [ ] Mobile-responsive onboarding

## Technical Notes
- Create onboarding modal: `src/components/onboarding/WelcomeModal.tsx`
- Track onboarding completion in users table or localStorage
- Add column to users: `onboarding_completed BOOLEAN DEFAULT FALSE`
- Or use localStorage: `localStorage.setItem('onboarding_completed', 'true')`
- Show modal on first dashboard visit after signup
- Multi-step modal:
  1. Welcome + plan info
  2. Create collection prompt
  3. Upload image tutorial
  4. Dashboard tour
- Use library like react-joyride for feature tours (optional)
- **GOTCHA**: Don't show onboarding if user has already created collections
- **TODO**: Add interactive tutorial tooltips (future enhancement)
- Skip button should mark onboarding as complete

## Architecture Reference
- ARCHITECTURE.md: Onboarding Experience
- User story: "show usage limits" and "CTA to upload first image"
