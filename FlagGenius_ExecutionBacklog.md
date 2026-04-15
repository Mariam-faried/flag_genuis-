# Flag Genius - Execution Backlog

This file converts the approved project plan into actionable implementation tasks.

## Sprint Timeline (6 Weeks)

### Week 1 - Foundation
- [x] Setup Flutter app architecture (routes, theme, folders).
- [x] Add core dependencies in `pubspec.yaml`.
- [x] Implement `ApiService` for REST Countries.
- [x] Implement `CountryModel` and `QuestionModel`.
- [x] Implement `QuestionGenerator` for 4 quiz modes + random mix.
- [x] Implement `QuizProvider` with timer, lives, scoring, streak multiplier, and badges logic.

### Week 2 - Entry Flow
- [x] Build Splash screen with initial countries loading.
- [x] Build 3-slide onboarding flow with first-launch persistence.
- [x] Build Login screen UI with guest path.
- [x] Wire Firebase Authentication (email/password + Google + anonymous).

### Week 3 - Main Navigation
- [x] Build Home dashboard UI with stats and mode shortcuts.
- [x] Build Mode Selection screen (mode + difficulty).
- [ ] Add bottom navigation and persistent shell navigation.
- [ ] Connect mini leaderboard preview to Firestore.

### Week 4 - Core Gameplay
- [x] Build main Quiz screen with:
  - [x] Timer bar.
  - [x] Lives indicator.
  - [x] Streak and score display.
  - [x] Answer feedback state.
- [x] Enforce scoring rules:
  - [x] 0-3 sec: 20 points.
  - [x] 3-6 sec: 15 points.
  - [x] 6-10 sec: 10 points.
  - [x] Wrong answer: lose one life.
  - [x] Streak 5+: x1.5 multiplier.
- [ ] Add dedicated per-question Result Screen in active flow.

### Week 5 - Post-Game + Social
- [x] Build Summary screen with stars and unlocked badges.
- [x] Build Leaderboard UI screen scaffold.
- [x] Build Profile screen scaffold.
- [x] Connect leaderboard to Firestore top 50 query.
- [x] Persist and sync profile stats from Firebase users collection.
- [x] Highlight current user rank in real leaderboard data.

### Week 6 - Polish + Extras
- [x] Build Settings screen with local toggles persistence.
- [x] Build Country Explorer with search + country details sheet.
- [x] Add 8 badges definitions and unlock checks.
- [ ] Add audio/vibration feedback integration.
- [ ] Add final animations and micro-interactions.
- [ ] End-to-end device testing and bug fixing.

## Team Ownership Map (5 Members)

### Member 1 - API + Generator + Explorer
- [x] REST Countries integration.
- [x] Data models for country payload.
- [x] Dynamic question generation.
- [x] Country Explorer screen.

### Member 2 - Firebase
- [x] Firebase project setup.
- [x] Authentication service.
- [x] Firestore users + leaderboard repositories.
- [x] Security rules and testing.

### Member 3 - Gameplay Core
- [x] Timer and lives system.
- [x] Score and streak multiplier logic.
- [x] Round progression and completion handling.
- [ ] Gameplay edge-case tests.

### Member 4 - Entry + Dashboard
- [x] Splash screen.
- [x] Onboarding flow.
- [x] Home dashboard.
- [x] Mode selection.

### Member 5 - Profile + Settings + Badges + Polish
- [x] Profile scaffold.
- [x] Settings persistence scaffold.
- [x] Badges metadata and unlock strategy.
- [ ] Final UI polish pass.
- [ ] Sound/vibration implementation.

## Next Priority (Immediate)
1. Add integration tests for quiz flow, auth session flow, and scoring rules.
2. Add dedicated per-question Result Screen in active flow.
3. Add audio/vibration integration with settings toggles and QA pass.
4. Add bottom navigation + persistent shell navigation for faster mode switching.
