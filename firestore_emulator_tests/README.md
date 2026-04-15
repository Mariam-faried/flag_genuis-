# Firestore Emulator Tests

This folder contains Firestore Security Rules tests for Flag Genius.

## What Is Covered
- `users/{uid}` owner-only read/write for private profile progress.
- `users` collection listing blocked for client apps.
- `leaderboard/{uid}` authenticated read access with owner-only writes.
- `leaderboard/{uid}` monotonic updates (no score/games regression).

## Install
```powershell
npm.cmd --prefix .\firestore_emulator_tests install
```

## Run
```powershell
$env:XDG_CONFIG_HOME = "$PWD\.firebase-config"
firebase.cmd --config .\firebase.emulators.json emulators:exec --project demo-flag-genius --only firestore "npm.cmd --prefix .\firestore_emulator_tests test"
```
