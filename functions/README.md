# Flag Genius Cloud Functions

This folder contains callable backend logic for tamper-resistant Daily Challenge flow:

- `startDailyChallenge`: Auth-required callable that creates/loads the server challenge session and returns the current question payload.
- `submitDailyChallengeAnswer`: Auth-required callable that validates an answer on the server, computes score/lives/streak, advances question state, and finalizes progress + leaderboard on completion.

## Install

```powershell
npm.cmd --prefix .\functions install
```

## Run with emulators

```powershell
firebase.cmd --config .\firebase.emulators.json emulators:start --only functions,firestore
```

## Deploy

```powershell
firebase.cmd deploy --only functions
```
