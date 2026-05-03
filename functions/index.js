const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

setGlobalOptions({ region: "us-central1", maxInstances: 10 });

const db = admin.firestore();

const MAX_LIVES = 3;
const QUESTION_TIME_LIMIT_SECONDS = 10;
const DAILY_CHALLENGE_ROOT = "dailyChallenges";
const COUNTRIES_URL =
  "https://restcountries.com/v3.1/all?fields=name,flags,capital,population,region,subregion,languages";
const COUNTRIES_CACHE_TTL_MS = 1000 * 60 * 60 * 12;

let countriesCache = {
  fetchedAt: 0,
  countries: [],
};

exports.startDailyChallenge = onCall(async (request) => {
  const uid = requireAuth(request);
  const dateKey = toUtcDateKey(new Date());

  const challenge = await getOrCreateDailyChallenge(dateKey);
  const participantRef = db
    .collection(DAILY_CHALLENGE_ROOT)
    .doc(dateKey)
    .collection("participants")
    .doc(uid);

  const participantSnap = await participantRef.get();
  if (participantSnap.exists) {
    const participant = participantSnap.data() || {};
    const status = String(participant.status || "in_progress");

    if (status === "completed") {
      return {
        status: "completed",
        dateKey,
        mode: challenge.mode,
        difficulty: challenge.difficulty,
        questionCount: challenge.questionCount,
        summary: buildSummaryPayload(participant),
      };
    }

    const currentQuestionIndex = clampInt(
      participant.currentQuestionIndex,
      0,
      Math.max(0, challenge.questionCount - 1),
    );
    const question = challenge.questions[currentQuestionIndex];

    return {
      status: "in_progress",
      dateKey,
      mode: challenge.mode,
      difficulty: challenge.difficulty,
      questionCount: challenge.questionCount,
      currentQuestionIndex,
      question: sanitizeQuestionForClient(question),
      score: clampInt(participant.score, 0, 1000000),
      lives: clampInt(participant.lives, 0, MAX_LIVES),
      streak: clampInt(participant.streak, 0, 100000),
      longestStreak: clampInt(participant.longestStreak, 0, 100000),
      correctAnswers: clampInt(participant.correctAnswers, 0, 100000),
      wrongAnswers: clampInt(participant.wrongAnswers, 0, 100000),
    };
  }

  const now = admin.firestore.Timestamp.now();
  const initialState = {
    status: "in_progress",
    currentQuestionIndex: 0,
    score: 0,
    lives: MAX_LIVES,
    streak: 0,
    longestStreak: 0,
    correctAnswers: 0,
    wrongAnswers: 0,
    answers: [],
    startedAt: now,
    currentQuestionStartedAt: now,
    completedAt: null,
    updatedAt: now,
  };

  await participantRef.set(initialState);

  return {
    status: "in_progress",
    dateKey,
    mode: challenge.mode,
    difficulty: challenge.difficulty,
    questionCount: challenge.questionCount,
    currentQuestionIndex: 0,
    question: sanitizeQuestionForClient(challenge.questions[0]),
    score: 0,
    lives: MAX_LIVES,
    streak: 0,
    longestStreak: 0,
    correctAnswers: 0,
    wrongAnswers: 0,
  };
});

exports.submitDailyChallengeAnswer = onCall(async (request) => {
  const uid = requireAuth(request);
  const input = toMap(request.data);

  const dateKeyRaw = String(input.dateKey || "").trim();
  const dateKey = isValidDateKey(dateKeyRaw)
    ? dateKeyRaw
    : toUtcDateKey(new Date());
  const selectedAnswerInput = normalizeAnswer(input.selectedAnswer);

  const challengeRef = db.collection(DAILY_CHALLENGE_ROOT).doc(dateKey);
  const participantRef = challengeRef.collection("participants").doc(uid);

  const identity = readIdentityFromAuth(request.auth);

  const response = await db.runTransaction(async (tx) => {
    const challengeSnap = await tx.get(challengeRef);
    if (!challengeSnap.exists) {
      throw new HttpsError(
        "failed-precondition",
        "Daily challenge is unavailable. Please start again.",
      );
    }

    const challenge = challengeSnap.data() || {};
    const questions = Array.isArray(challenge.questions)
      ? challenge.questions
      : [];
    if (questions.length === 0) {
      throw new HttpsError(
        "internal",
        "Daily challenge questions are missing.",
      );
    }

    const participantSnap = await tx.get(participantRef);
    if (!participantSnap.exists) {
      throw new HttpsError(
        "failed-precondition",
        "Daily challenge session was not found. Start again.",
      );
    }

    const participant = participantSnap.data() || {};
    const status = String(participant.status || "in_progress");
    if (status === "completed") {
      return {
        status: "completed",
        dateKey,
        mode: String(challenge.mode || "flag"),
        difficulty: String(challenge.difficulty || "medium"),
        questionCount: clampInt(challenge.questionCount, 1, 12),
        roundOver: true,
        summary: buildSummaryPayload(participant),
      };
    }

    const questionCount = clampInt(challenge.questionCount, 1, questions.length);
    const currentQuestionIndex = clampInt(
      participant.currentQuestionIndex,
      0,
      Math.max(0, questionCount - 1),
    );
    const question = questions[currentQuestionIndex];
    if (!question || !Array.isArray(question.options)) {
      throw new HttpsError("internal", "Question payload is invalid.");
    }

    const now = admin.firestore.Timestamp.now();
    const startedAt = participant.currentQuestionStartedAt instanceof admin.firestore.Timestamp
      ? participant.currentQuestionStartedAt
      : now;
    const elapsedSeconds = Math.max(
      0,
      Math.floor((now.toMillis() - startedAt.toMillis()) / 1000),
    );

    let selectedAnswer = selectedAnswerInput;
    const options = question.options
      .map((entry) => String(entry))
      .map((entry) => entry.trim())
      .filter((entry) => entry.length > 0);
    if (selectedAnswer != null && !options.includes(selectedAnswer)) {
      selectedAnswer = null;
    }

    const timedOut = elapsedSeconds >= QUESTION_TIME_LIMIT_SECONDS;
    const correctAnswer = String(question.correctAnswer || "").trim();
    const isCorrect =
      !timedOut &&
      selectedAnswer != null &&
      correctAnswer.length > 0 &&
      selectedAnswer === correctAnswer;

    const previousScore = clampInt(participant.score, 0, 1000000);
    const previousStreak = clampInt(participant.streak, 0, 100000);
    const previousLongestStreak = clampInt(participant.longestStreak, 0, 100000);
    const previousLives = clampInt(participant.lives, 0, MAX_LIVES);
    const previousCorrectAnswers = clampInt(participant.correctAnswers, 0, 100000);
    const previousWrongAnswers = clampInt(participant.wrongAnswers, 0, 100000);

    const points = isCorrect
      ? calculatePoints(elapsedSeconds, previousStreak + 1)
      : 0;
    const score = clampInt(previousScore + points, 0, 1000000);
    const streak = isCorrect ? previousStreak + 1 : 0;
    const longestStreak = Math.max(previousLongestStreak, streak);
    const lives = isCorrect ? previousLives : Math.max(0, previousLives - 1);
    const correctAnswers = isCorrect
      ? previousCorrectAnswers + 1
      : previousCorrectAnswers;
    const wrongAnswers = isCorrect
      ? previousWrongAnswers
      : previousWrongAnswers + 1;

    const answerRecord = {
      questionId: String(question.id || `q${currentQuestionIndex + 1}`),
      selectedAnswer,
      isCorrect,
      correctAnswer,
      points,
      elapsedSeconds: Math.min(elapsedSeconds, QUESTION_TIME_LIMIT_SECONDS),
      answeredAt: now,
    };

    const previousAnswers = Array.isArray(participant.answers)
      ? participant.answers
      : [];
    const answers = [...previousAnswers, answerRecord];

    const isLastQuestion = currentQuestionIndex >= questionCount - 1;
    const roundOver = lives <= 0 || isLastQuestion;

    const participantUpdate = {
      score,
      streak,
      longestStreak,
      lives,
      correctAnswers,
      wrongAnswers,
      answers,
      updatedAt: now,
    };

    if (roundOver) {
      participantUpdate.status = "completed";
      participantUpdate.completedAt = now;
      participantUpdate.currentQuestionIndex = currentQuestionIndex;
      participantUpdate.currentQuestionStartedAt = now;
      tx.set(participantRef, participantUpdate, { merge: true });

      const userSummary = await applyDailyCompletionProgressUpdate({
        tx,
        uid,
        identity,
        score,
        dateKey,
        now,
      });

      tx.set(
        participantRef,
        { dailyChallengeStreak: userSummary.dailyChallengeStreak },
        { merge: true },
      );

      return {
        status: "completed",
        dateKey,
        mode: String(challenge.mode || "flag"),
        difficulty: String(challenge.difficulty || "medium"),
        questionCount,
        roundOver: true,
        score,
        lives,
        streak,
        longestStreak,
        correctAnswers,
        wrongAnswers,
        answerResult: {
          selectedAnswer,
          isCorrect,
          correctAnswer,
          points,
          elapsedSeconds: Math.min(elapsedSeconds, QUESTION_TIME_LIMIT_SECONDS),
          funFact: question.funFact || null,
        },
        summary: {
          score,
          correctAnswers,
          wrongAnswers,
          longestStreak,
          dailyChallengeStreak: userSummary.dailyChallengeStreak,
        },
      };
    }

    const nextQuestionIndex = currentQuestionIndex + 1;
    participantUpdate.status = "in_progress";
    participantUpdate.currentQuestionIndex = nextQuestionIndex;
    participantUpdate.currentQuestionStartedAt = now;
    participantUpdate.completedAt = null;
    tx.set(participantRef, participantUpdate, { merge: true });

    return {
      status: "in_progress",
      dateKey,
      mode: String(challenge.mode || "flag"),
      difficulty: String(challenge.difficulty || "medium"),
      questionCount,
      roundOver: false,
      score,
      lives,
      streak,
      longestStreak,
      correctAnswers,
      wrongAnswers,
      answerResult: {
        selectedAnswer,
        isCorrect,
        correctAnswer,
        points,
        elapsedSeconds: Math.min(elapsedSeconds, QUESTION_TIME_LIMIT_SECONDS),
        funFact: question.funFact || null,
      },
      nextQuestion: sanitizeQuestionForClient(questions[nextQuestionIndex]),
    };
  });

  return response;
});

exports.syncUserProgressSecure = onCall(async (request) => {
  const uid = requireAuth(request);
  const input = toMap(request.data);
  const identity = readIdentityFromAuth(request.auth);
  const now = admin.firestore.Timestamp.now();

  return db.runTransaction(async (tx) => {
    const usersRef = db.collection("users").doc(uid);
    const leaderboardRef = db.collection("leaderboard").doc(uid);

    const userSnap = await tx.get(usersRef);
    const leaderboardSnap = await tx.get(leaderboardRef);
    const userData = userSnap.exists ? userSnap.data() || {} : {};
    const leaderboardData = leaderboardSnap.exists
      ? leaderboardSnap.data() || {}
      : {};

    const incomingGamesPlayed = clampInt(input.gamesPlayed, 0, 1000000);
    const incomingLifetimeScore = clampInt(input.lifetimeScore, 0, 100000000);
    const incomingBestScore = clampInt(input.bestScore, 0, 1000);
    const incomingDailyChallengeStreak = clampInt(
      input.dailyChallengeStreak,
      0,
      10000,
    );
    const incomingLatestRoundScore = clampInt(input.latestRoundScore, 0, 1000);
    const incomingEarnedBadges = normalizeBadgeNames(input.earnedBadgeNames);
    const incomingLastDailyChallengeDate = parseOptionalIsoDate(
      input.lastDailyChallengeDateIso,
    );

    const existingGamesPlayed = clampInt(userData.gamesPlayed, 0, 1000000);
    const existingBestScore = clampInt(userData.bestScore, 0, 1000);
    const rawExistingLifetimeScore = clampInt(
      userData.lifetimeScore,
      0,
      100000000,
    );
    const existingLeaderboardGamesPlayed = clampInt(
      leaderboardData.gamesPlayed,
      0,
      1000000,
    );
    const existingLeaderboardBestScore = clampInt(
      leaderboardData.bestScore,
      0,
      1000,
    );
    const existingEarnedBadges = normalizeBadgeNames(userData.earnedBadges);
    const existingLastDailyChallengeAt =
      userData.lastDailyChallengeAt instanceof admin.firestore.Timestamp
        ? userData.lastDailyChallengeAt
        : null;

    const canonicalGamesPlayed = Math.max(
      existingGamesPlayed,
      existingLeaderboardGamesPlayed,
      incomingGamesPlayed,
    );
    const canonicalBestScore = clampInt(
      Math.max(
        existingBestScore,
        existingLeaderboardBestScore,
        incomingBestScore,
        incomingLatestRoundScore,
      ),
      0,
      1000,
    );
    const existingLifetimeScore = Math.max(
      rawExistingLifetimeScore,
      existingBestScore,
      existingLeaderboardBestScore,
    );
    const canonicalLifetimeScore = clampInt(
      Math.max(incomingLifetimeScore, existingLifetimeScore, canonicalBestScore),
      0,
      100000000,
    );
    const canonicalDailyChallengeStreak = clampInt(
      incomingDailyChallengeStreak,
      0,
      10000,
    );

    const earnedBadges = Array.from(
      new Set([...existingEarnedBadges, ...incomingEarnedBadges]),
    ).sort();

    const createdAt =
      userData.createdAt instanceof admin.firestore.Timestamp
        ? userData.createdAt
        : now;

    const lastDailyChallengeAt = incomingLastDailyChallengeDate
      ? admin.firestore.Timestamp.fromDate(incomingLastDailyChallengeDate)
      : existingLastDailyChallengeAt;

    tx.set(
      usersRef,
      {
        displayName: identity.displayName,
        email: identity.email,
        photoUrl: identity.photoUrl,
        isAnonymous: identity.isAnonymous,
        gamesPlayed: canonicalGamesPlayed,
        lifetimeScore: canonicalLifetimeScore,
        bestScore: canonicalBestScore,
        dailyChallengeStreak: canonicalDailyChallengeStreak,
        earnedBadges,
        lastDailyChallengeAt,
        updatedAt: now,
        createdAt,
      },
      { merge: true },
    );

    tx.set(
      leaderboardRef,
      {
        displayName: identity.displayName,
        photoUrl: identity.photoUrl,
        bestScore: canonicalBestScore,
        gamesPlayed: canonicalGamesPlayed,
        updatedAt: now,
      },
      { merge: true },
    );

    return {
      status: "ok",
      gamesPlayed: canonicalGamesPlayed,
      lifetimeScore: canonicalLifetimeScore,
      bestScore: canonicalBestScore,
      dailyChallengeStreak: canonicalDailyChallengeStreak,
      secureWrite: true,
    };
  });
});

function requireAuth(request) {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }
  return uid;
}

function readIdentityFromAuth(auth) {
  const token = auth?.token || {};
  const email = typeof token.email === "string" ? token.email.trim() : null;
  const displayNameFromToken =
    typeof token.name === "string" ? token.name.trim() : "";
  const displayNameFromEmail =
    email && email.includes("@") ? email.split("@")[0] : "";

  return {
    email,
    photoUrl: typeof token.picture === "string" ? token.picture.trim() : null,
    displayName:
      displayNameFromToken || displayNameFromEmail || `Guest ${auth.uid.slice(0, 6)}`,
    isAnonymous:
      auth?.token?.firebase?.sign_in_provider === "anonymous" || !email,
  };
}

async function getOrCreateDailyChallenge(dateKey) {
  const ref = db.collection(DAILY_CHALLENGE_ROOT).doc(dateKey);
  let snapshot = await ref.get();
  if (snapshot.exists) {
    return snapshot.data();
  }

  const generated = await generateChallengeForDate(dateKey);

  try {
    await ref.create(generated);
    snapshot = await ref.get();
    return snapshot.data();
  } catch (error) {
    if (String(error.code || "").toLowerCase() !== "already-exists") {
      logger.error("Failed to create daily challenge", error);
    }
    const existing = await ref.get();
    if (!existing.exists) {
      throw new HttpsError(
        "internal",
        "Could not initialize daily challenge.",
      );
    }
    return existing.data();
  }
}

async function generateChallengeForDate(dateKey) {
  const config = dailyConfigForDateKey(dateKey);
  const countries = await fetchCountries();
  if (countries.length < 20) {
    throw new HttpsError(
      "internal",
      "Country source is too small for challenge generation.",
    );
  }

  const random = createSeededRandom(config.seed);
  const questions = generateQuestions({
    countries,
    mode: config.mode,
    count: config.questionCount,
    random,
  });

  return {
    dateKey,
    mode: config.mode,
    difficulty: config.difficulty,
    questionCount: config.questionCount,
    questions,
    createdAt: admin.firestore.Timestamp.now(),
    updatedAt: admin.firestore.Timestamp.now(),
    version: 1,
  };
}

async function fetchCountries() {
  const now = Date.now();
  if (
    countriesCache.countries.length >= 20 &&
    now - countriesCache.fetchedAt < COUNTRIES_CACHE_TTL_MS
  ) {
    return countriesCache.countries;
  }

  const response = await fetch(COUNTRIES_URL);
  if (!response.ok) {
    throw new HttpsError(
      "internal",
      `REST Countries failed with status ${response.status}`,
    );
  }

  const raw = await response.json();
  if (!Array.isArray(raw)) {
    throw new HttpsError(
      "internal",
      "REST Countries response is not a list.",
    );
  }

  const countries = raw
    .map(toCountryRecord)
    .filter((country) => country.nameCommon !== "Unknown")
    .sort((a, b) => a.nameCommon.localeCompare(b.nameCommon));

  countriesCache = { fetchedAt: now, countries };
  return countries;
}

function toCountryRecord(raw) {
  const name = toMap(raw?.name);
  const flags = toMap(raw?.flags);
  const languagesMap = toMap(raw?.languages);

  return {
    nameCommon: normalizeText(name.common) || "Unknown",
    flagPng: normalizeText(flags.png),
    capital: Array.isArray(raw?.capital)
      ? raw.capital
          .map((entry) => normalizeText(entry))
          .filter((entry) => entry.length > 0)
      : [],
    population: clampInt(raw?.population, 0, 2000000000),
    region: normalizeText(raw?.region),
    subregion: normalizeText(raw?.subregion),
    languages: Object.values(languagesMap)
      .map((entry) => normalizeText(entry))
      .filter((entry) => entry.length > 0),
  };
}

function generateQuestions({ countries, mode, count, random }) {
  if (!Array.isArray(countries) || countries.length < 4) {
    return [];
  }

  const questions = [];
  const maxAttempts = count * 14;
  let attempts = 0;

  while (questions.length < count && attempts < maxAttempts) {
    attempts += 1;
    const question =
      mode === "flag"
        ? buildFlagQuestion(countries, random)
        : mode === "capital"
        ? buildCapitalQuestion(countries, random)
        : mode === "population"
        ? buildPopulationQuestion(countries, random)
        : buildRegionQuestion(countries, random);

    if (!question) {
      continue;
    }

    questions.push({
      id: `q${questions.length + 1}`,
      ...question,
    });
  }

  if (questions.length < count) {
    throw new HttpsError(
      "internal",
      "Could not generate enough daily challenge questions.",
    );
  }

  return questions;
}

function buildFlagQuestion(countries, random) {
  const valid = countries.filter(
    (country) => country.flagPng && country.nameCommon.length > 0,
  );
  if (valid.length < 4) {
    return null;
  }

  const correct = pickOne(valid, random);
  const wrongOptions = collectUniqueOptions({
    source: valid,
    excludedCountryName: correct.nameCommon,
    mapper: (country) => country.nameCommon,
    neededCount: 3,
    random,
  });
  if (wrongOptions.length < 3) {
    return null;
  }

  const options = shuffle([...wrongOptions, correct.nameCommon], random);
  return {
    mode: "flag",
    prompt: "Which country does this flag belong to?",
    options,
    correctAnswer: correct.nameCommon,
    visualUrl: correct.flagPng,
    funFact: buildFunFact(correct),
  };
}

function buildCapitalQuestion(countries, random) {
  const valid = countries.filter(
    (country) => Array.isArray(country.capital) && country.capital.length > 0,
  );
  if (valid.length < 4) {
    return null;
  }

  const correct = pickOne(valid, random);
  const correctCapital = correct.capital[0];
  const wrongOptions = collectUniqueOptions({
    source: valid,
    excludedCountryName: correct.nameCommon,
    mapper: (country) => country.capital[0] || "",
    neededCount: 3,
    random,
  });
  if (wrongOptions.length < 3) {
    return null;
  }

  const options = shuffle([...wrongOptions, correctCapital], random);
  return {
    mode: "capital",
    prompt: `What is the capital of ${correct.nameCommon}?`,
    options,
    correctAnswer: correctCapital,
    visualUrl: null,
    funFact: buildFunFact(correct),
  };
}

function buildPopulationQuestion(countries, random) {
  const valid = countries.filter((country) => country.population > 0);
  if (valid.length < 4) {
    return null;
  }

  const sample = shuffle([...valid], random).slice(0, 4);
  const correct = sample.reduce((current, next) =>
    current.population >= next.population ? current : next,
  );
  const options = shuffle(sample.map((country) => country.nameCommon), random);

  return {
    mode: "population",
    prompt: "Which country has the highest population?",
    options,
    correctAnswer: correct.nameCommon,
    visualUrl: null,
    funFact: `${correct.nameCommon} has around ${formatPopulation(correct.population)} people.`,
  };
}

function buildRegionQuestion(countries, random) {
  const valid = countries.filter((country) => normalizeText(country.region));
  const regionPool = Array.from(
    new Set(
      valid
        .map((country) => normalizeText(country.region))
        .filter((region) => region.length > 0),
    ),
  );

  if (valid.length < 4 || regionPool.length < 4) {
    return null;
  }

  const correct = pickOne(valid, random);
  const correctRegion = normalizeText(correct.region);
  const wrongRegions = shuffle(
    regionPool.filter((region) => region !== correctRegion),
    random,
  );
  if (wrongRegions.length < 3) {
    return null;
  }

  const options = shuffle(
    [correctRegion, wrongRegions[0], wrongRegions[1], wrongRegions[2]],
    random,
  );

  return {
    mode: "region",
    prompt: `Which region does ${correct.nameCommon} belong to?`,
    options,
    correctAnswer: correctRegion,
    visualUrl: null,
    funFact: buildFunFact(correct),
  };
}

function collectUniqueOptions({
  source,
  excludedCountryName,
  mapper,
  neededCount,
  random,
}) {
  const shuffled = shuffle([...source], random);
  const values = new Set();
  for (const country of shuffled) {
    if (country.nameCommon === excludedCountryName) {
      continue;
    }
    const mapped = normalizeText(mapper(country));
    if (!mapped) {
      continue;
    }
    values.add(mapped);
    if (values.size >= neededCount) {
      break;
    }
  }
  return Array.from(values);
}

function buildFunFact(country) {
  const region = normalizeText(country.region) || "Unknown";
  const parts = [
    `${country.nameCommon} is part of ${region}.`,
    `Population: ${formatPopulation(country.population)}.`,
  ];
  if (Array.isArray(country.capital) && country.capital.length > 0) {
    parts.push(`Capital: ${country.capital[0]}.`);
  }
  return parts.join(" ");
}

function sanitizeQuestionForClient(question) {
  return {
    id: String(question?.id || ""),
    mode: String(question?.mode || "flag"),
    prompt: String(question?.prompt || ""),
    options: Array.isArray(question?.options)
      ? question.options.map((entry) => String(entry))
      : [],
    visualUrl:
      typeof question?.visualUrl === "string" && question.visualUrl.trim()
        ? question.visualUrl.trim()
        : null,
  };
}

function dailyConfigForDateKey(dateKey) {
  const [yearText, monthText, dayText] = dateKey.split("-");
  const year = Number(yearText);
  const month = Number(monthText);
  const day = Number(dayText);
  const date = new Date(Date.UTC(year, month - 1, day));
  const firstDay = new Date(Date.UTC(year, 0, 1));
  const dayOfYear =
    Math.floor((date.getTime() - firstDay.getTime()) / 86400000) + 1;
  const seed = year * 1000 + dayOfYear;

  const modes = ["flag", "capital", "population", "region"];
  const mode = modes[seed % modes.length];
  const difficulty = seed % 5 === 0 ? "hard" : "medium";
  const questionCount = difficulty === "hard" ? 12 : 10;

  return { seed, mode, difficulty, questionCount };
}

function toUtcDateKey(date) {
  const year = date.getUTCFullYear();
  const month = String(date.getUTCMonth() + 1).padStart(2, "0");
  const day = String(date.getUTCDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

function isValidDateKey(value) {
  return /^\d{4}-\d{2}-\d{2}$/.test(value);
}

function toMap(raw) {
  if (raw && typeof raw === "object" && !Array.isArray(raw)) {
    return raw;
  }
  return {};
}

function normalizeText(value) {
  if (typeof value !== "string") {
    return "";
  }
  return value.trim();
}

function normalizeAnswer(value) {
  if (typeof value !== "string") {
    return null;
  }
  const answer = value.trim();
  return answer.length > 0 ? answer : null;
}

function normalizeBadgeNames(value) {
  if (!Array.isArray(value)) {
    return [];
  }
  return Array.from(
    new Set(
      value
        .map((entry) => String(entry))
        .map((entry) => entry.trim())
        .filter((entry) => entry.length > 0),
    ),
  ).sort();
}

function parseOptionalIsoDate(value) {
  if (typeof value !== "string" || value.trim().length === 0) {
    return null;
  }
  const parsed = new Date(value);
  if (Number.isNaN(parsed.getTime())) {
    return null;
  }
  return parsed;
}

function clampInt(value, min, max) {
  const number = Number.isFinite(Number(value)) ? Number(value) : min;
  return Math.max(min, Math.min(max, Math.floor(number)));
}

function createSeededRandom(seed) {
  let state = seed >>> 0;
  return () => {
    state += 0x6d2b79f5;
    let result = Math.imul(state ^ (state >>> 15), state | 1);
    result ^= result + Math.imul(result ^ (result >>> 7), result | 61);
    return ((result ^ (result >>> 14)) >>> 0) / 4294967296;
  };
}

function shuffle(array, random) {
  for (let index = array.length - 1; index > 0; index -= 1) {
    const swapIndex = Math.floor(random() * (index + 1));
    [array[index], array[swapIndex]] = [array[swapIndex], array[index]];
  }
  return array;
}

function pickOne(array, random) {
  return array[Math.floor(random() * array.length)];
}

function calculatePoints(elapsedSeconds, streakAfterAnswer) {
  const basePoints =
    elapsedSeconds <= 3 ? 20 : elapsedSeconds <= 6 ? 15 : elapsedSeconds <= 10 ? 10 : 0;
  if (basePoints <= 0) {
    return 0;
  }
  if (streakAfterAnswer < 5) {
    return basePoints;
  }
  return Math.round(basePoints * 1.5);
}

function formatPopulation(value) {
  const safeValue = clampInt(value, 0, 2000000000);
  return String(safeValue).replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

function buildSummaryPayload(participant) {
  return {
    score: clampInt(participant.score, 0, 1000000),
    correctAnswers: clampInt(participant.correctAnswers, 0, 100000),
    wrongAnswers: clampInt(participant.wrongAnswers, 0, 100000),
    longestStreak: clampInt(participant.longestStreak, 0, 100000),
    dailyChallengeStreak: clampInt(participant.dailyChallengeStreak, 0, 10000),
  };
}

async function applyDailyCompletionProgressUpdate({
  tx,
  uid,
  identity,
  score,
  dateKey,
  now,
}) {
  const usersRef = db.collection("users").doc(uid);
  const leaderboardRef = db.collection("leaderboard").doc(uid);

  const userSnap = await tx.get(usersRef);
  const userData = userSnap.exists ? userSnap.data() || {} : {};

  const existingGamesPlayed = clampInt(userData.gamesPlayed, 0, 1000000);
  const existingBestScore = clampInt(userData.bestScore, 0, 100000000);
  const rawLifetimeScore = clampInt(userData.lifetimeScore, 0, 100000000);
  const existingLifetimeScore =
    rawLifetimeScore < existingBestScore ? existingBestScore : rawLifetimeScore;

  const gamesPlayed = clampInt(existingGamesPlayed + 1, 0, 1000000);
  const lifetimeScore = clampInt(existingLifetimeScore + score, 0, 100000000);
  const bestScore = Math.max(existingBestScore, score);

  const previousDailyDate = userData.lastDailyChallengeAt instanceof admin.firestore.Timestamp
    ? userData.lastDailyChallengeAt.toDate()
    : null;
  const completionDate = dateFromDateKeyUtc(dateKey);
  const previousStreak = clampInt(userData.dailyChallengeStreak, 0, 10000);
  const dailyChallengeStreak = computeDailyStreak({
    previousDate: previousDailyDate,
    completionDate,
    previousStreak,
  });

  const earnedBadges = Array.isArray(userData.earnedBadges)
    ? Array.from(
        new Set(
          userData.earnedBadges
            .map((entry) => String(entry))
            .map((entry) => entry.trim())
            .filter((entry) => entry.length > 0),
        ),
      ).sort()
    : [];

  const createdAt =
    userData.createdAt instanceof admin.firestore.Timestamp
      ? userData.createdAt
      : now;

  tx.set(
    usersRef,
    {
      displayName: identity.displayName,
      email: identity.email,
      photoUrl: identity.photoUrl,
      isAnonymous: identity.isAnonymous,
      gamesPlayed,
      lifetimeScore,
      bestScore,
      dailyChallengeStreak,
      earnedBadges,
      lastDailyChallengeAt: admin.firestore.Timestamp.fromDate(completionDate),
      updatedAt: now,
      createdAt,
    },
    { merge: true },
  );

  tx.set(
    leaderboardRef,
    {
      displayName: identity.displayName,
      photoUrl: identity.photoUrl,
      bestScore: Math.min(bestScore, 1000),
      gamesPlayed,
      updatedAt: now,
    },
    { merge: true },
  );

  return {
    dailyChallengeStreak,
    gamesPlayed,
    lifetimeScore,
    bestScore,
  };
}

function computeDailyStreak({ previousDate, completionDate, previousStreak }) {
  if (!(previousDate instanceof Date)) {
    return 1;
  }

  const previousUtc = Date.UTC(
    previousDate.getUTCFullYear(),
    previousDate.getUTCMonth(),
    previousDate.getUTCDate(),
  );
  const completionUtc = Date.UTC(
    completionDate.getUTCFullYear(),
    completionDate.getUTCMonth(),
    completionDate.getUTCDate(),
  );
  const daysDiff = Math.floor((completionUtc - previousUtc) / 86400000);

  if (daysDiff <= 0) {
    return previousStreak;
  }
  if (daysDiff === 1) {
    return clampInt(previousStreak + 1, 0, 10000);
  }
  return 1;
}

function dateFromDateKeyUtc(dateKey) {
  const [yearText, monthText, dayText] = dateKey.split("-");
  const year = Number(yearText);
  const month = Number(monthText);
  const day = Number(dayText);
  return new Date(Date.UTC(year, month - 1, day));
}
