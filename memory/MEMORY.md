# MomCare iOS — Persistent Memory

## Project Status
- MOM-23 merged (PR #9): Feeding integration, content rotation tests, comprehensive audit fixes
- Main branch is current with all features through MOM-23

## Architecture
- Stack: SwiftUI + @Observable + SwiftData + Firebase (iOS 17+)
- Clean Architecture: View → ViewModel (@Observable) → Repository (protocol) → SwiftData
- Swift 6 strict concurrency enforced throughout
- Testing: Swift Testing framework (#expect, @Suite, @Test) — no XCTest

## Key Patterns
- All View structs need @MainActor for Swift 6 compliance
- ViewModel derived data (filter/sort) belongs on ViewModel, not in body
- Animations must respect @Environment(\.accessibilityReduceMotion)
- Force unwrap in tests → use try #require instead

## Known Issues / Tech Debt
- GoogleService-Info.plist has live Firebase credentials committed to git history
  → Requires: rotate key in Firebase Console + git filter-repo to scrub history

## API Notes
- Font.system(size:) does NOT support relativeTo: — that's only for Font.custom()
- SourceKit false positives are common in this project (missing types/symbols) — trust the compiler, not SourceKit

## Completed Linear Issues
- MOM-21: Self-Care Event Engine
- MOM-20: Content Library & Pattern Service
- MOM-19: Self-Care Domain & Data Layer
- MOM-3: Feeding Tracking
- MOM-2: Baby management
- MOM-23: Feeding Integration & Final Tests + comprehensive audit fixes
