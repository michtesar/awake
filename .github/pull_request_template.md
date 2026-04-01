## Summary
- What changed and why?

## Checklist
- [ ] Tests added/updated (if behavior changed)
- [ ] `swift test --enable-code-coverage` passes locally
- [ ] Xcode build passes locally
- [ ] No secrets or local machine artifacts committed

## Validation
- Commands run:
  - `swift test --enable-code-coverage`
  - `xcodebuild -project awake.xcodeproj -scheme awake -configuration Debug -destination 'platform=macOS' build`

## Risks
- Any migration, behavior, or UX risks to watch for?
