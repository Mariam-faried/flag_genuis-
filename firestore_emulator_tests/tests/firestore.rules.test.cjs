const path = require('node:path');
const { readFileSync } = require('node:fs');
const test = require('node:test');

const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');

const {
  doc,
  setDoc,
  getDoc,
  getDocs,
  collection,
  query,
  orderBy,
  limit,
} = require('firebase/firestore');

const projectId = 'demo-flag-genius';

const [emulatorHost, emulatorPort] = (
  process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080'
).split(':');

const rules = readFileSync(
  path.resolve(__dirname, '..', '..', 'firestore.rules'),
  'utf8',
);

let testEnv;

function validUserDoc({
  displayName = 'Player',
  isAnonymous = false,
  gamesPlayed = 0,
  lifetimeScore = 0,
  bestScore = 0,
  dailyChallengeStreak = 0,
} = {}) {
  return {
    displayName,
    email: null,
    photoUrl: null,
    isAnonymous,
    gamesPlayed,
    lifetimeScore,
    bestScore,
    dailyChallengeStreak,
    earnedBadges: [],
    lastDailyChallengeAt: null,
    createdAt: new Date('2026-01-01T00:00:00.000Z'),
    updatedAt: new Date('2026-01-01T00:00:00.000Z'),
  };
}

function validLeaderboardDoc({
  displayName = 'Player',
  gamesPlayed = 0,
  bestScore = 0,
} = {}) {
  return {
    displayName,
    photoUrl: null,
    gamesPlayed,
    bestScore,
    updatedAt: new Date('2026-01-01T00:00:00.000Z'),
  };
}

async function seedData() {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const adminDb = context.firestore();
    await setDoc(
      doc(adminDb, 'users/alice'),
      validUserDoc({
        displayName: 'Alice',
        gamesPlayed: 10,
        lifetimeScore: 1200,
        bestScore: 250,
      }),
    );

    await setDoc(
      doc(adminDb, 'leaderboard/alice'),
      validLeaderboardDoc({
        displayName: 'Alice',
        gamesPlayed: 10,
        bestScore: 250,
      }),
    );

    await setDoc(
      doc(adminDb, 'users/bob'),
      validUserDoc({
        displayName: 'Bob',
        gamesPlayed: 8,
        lifetimeScore: 900,
        bestScore: 180,
      }),
    );

    await setDoc(
      doc(adminDb, 'leaderboard/bob'),
      validLeaderboardDoc({
        displayName: 'Bob',
        gamesPlayed: 8,
        bestScore: 180,
      }),
    );
  });
}

test.before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules,
      host: emulatorHost,
      port: Number(emulatorPort),
    },
  });
});

test.beforeEach(async () => {
  await testEnv.clearFirestore();
});

test.after(async () => {
  await testEnv.cleanup();
});

test('users/{uid}: authenticated user can write own profile document', async () => {
  const aliceDb = testEnv.authenticatedContext('alice').firestore();
  await assertSucceeds(
    setDoc(doc(aliceDb, 'users/alice'), validUserDoc({ displayName: 'Alice' })),
  );
});

test('users/{uid}: authenticated user cannot write another user profile document', async () => {
  const aliceDb = testEnv.authenticatedContext('alice').firestore();
  await assertFails(
    setDoc(doc(aliceDb, 'users/bob'), validUserDoc({ displayName: 'Bob' })),
  );
});

test('users/{uid}: unauthenticated user cannot write profile documents', async () => {
  const guestDb = testEnv.unauthenticatedContext().firestore();
  await assertFails(
    setDoc(
      doc(guestDb, 'users/guest'),
      validUserDoc({ displayName: 'Guest', isAnonymous: true }),
    ),
  );
});

test('users/{uid}: authenticated user cannot read another user private profile', async () => {
  await seedData();
  const aliceDb = testEnv.authenticatedContext('alice').firestore();
  await assertFails(getDoc(doc(aliceDb, 'users/bob')));
});

test('users collection list is blocked for clients', async () => {
  await seedData();
  const playerDb = testEnv.authenticatedContext('player-1').firestore();
  await assertFails(getDocs(collection(playerDb, 'users')));
});

test('leaderboard reads: authenticated users can read public leaderboard query', async () => {
  await seedData();
  const playerDb = testEnv.authenticatedContext('player-1').firestore();

  const leaderboardQuery = query(
    collection(playerDb, 'leaderboard'),
    orderBy('bestScore', 'desc'),
    limit(50),
  );

  await assertSucceeds(getDocs(leaderboardQuery));
});

test('leaderboard/{uid}: owner can create and update own leaderboard entry', async () => {
  const aliceDb = testEnv.authenticatedContext('alice').firestore();
  const aliceLeaderboardRef = doc(aliceDb, 'leaderboard/alice');

  await assertSucceeds(
    setDoc(
      aliceLeaderboardRef,
      validLeaderboardDoc({
        displayName: 'Alice',
        gamesPlayed: 1,
        bestScore: 120,
      }),
    ),
  );

  await assertSucceeds(
    setDoc(
      aliceLeaderboardRef,
      validLeaderboardDoc({
        displayName: 'Alice',
        gamesPlayed: 2,
        bestScore: 180,
      }),
      { merge: true },
    ),
  );
});

test('leaderboard/{uid}: owner cannot decrease bestScore or gamesPlayed', async () => {
  await seedData();
  const aliceDb = testEnv.authenticatedContext('alice').firestore();
  const aliceLeaderboardRef = doc(aliceDb, 'leaderboard/alice');

  await assertFails(
    setDoc(
      aliceLeaderboardRef,
      validLeaderboardDoc({
        displayName: 'Alice',
        gamesPlayed: 9,
        bestScore: 249,
      }),
      { merge: true },
    ),
  );
});

test('leaderboard/{uid}: user cannot write another user leaderboard entry', async () => {
  const aliceDb = testEnv.authenticatedContext('alice').firestore();
  await assertFails(
    setDoc(
      doc(aliceDb, 'leaderboard/bob'),
      validLeaderboardDoc({
        displayName: 'Bob',
        gamesPlayed: 1,
        bestScore: 100,
      }),
    ),
  );
});

test('leaderboard reads require authentication', async () => {
  await seedData();
  const guestDb = testEnv.unauthenticatedContext().firestore();
  await assertFails(getDoc(doc(guestDb, 'leaderboard/alice')));
});
