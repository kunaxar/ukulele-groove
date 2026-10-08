const patterns = [
  {
    "id": "steady",
    "name": "Steady downs",
    "meter": 4,
    "steps": ["D", "-", "D", "-", "D", "-", "D", "-"],
    "tip": "One downstroke on each beat. Miss the strings on every “and” while your hand keeps moving.",
  },
  {
    "id": "eighths",
    "name": "Down-up flow",
    "meter": 4,
    "steps": ["D", "U", "D", "U", "D", "U", "D", "U"],
    "tip": "Fill all eight slots. In this beginner pattern, strum down on the numbers and up on the “ands”.",
  },
  {
    "id": "island",
    "name": "Island bounce",
    "meter": 4,
    "steps": ["D", "-", "D", "U", "-", "U", "D", "U"],
    "tip": "Skip the “and” after 1 and the downstroke on 3. Keep moving through both gaps. The upstroke after 3 gives the bounce.",
  },
  {
    "id": "chuck",
    "name": "Muted backbeat",
    "meter": 4,
    "steps": ["D", "-", "X", "U", "-", "U", "X", "U"],
    "tip": "Replace the ringing strums on 2 and 4 with short, muted chucks. X makes a sound; a dash means miss the strings.",
  },
  {
    "id": "waltz",
    "name": "Three-beat sway",
    "meter": 3,
    "steps": ["D", "-", "D", "-", "D", "-"],
    "tip": "Count ONE-two-three. Give 1 a little more weight. Skip the strings on the “ands”.",
  },
];
const lessons = [
  {
    "id": "morning",
    "name": "Morning walk",
    "bpm": 88,
    "meter": 4,
    "best": "steady",
    "options": ["steady", "island", "eighths", "waltz"],
    "hear": "The melody lands on the main beats and leaves space between them.",
    "why": "Steady downs support this relaxed, on-the-beat melody without filling all its breathing room.",
    "rest": "Leave all four “and” slots empty. The chord can still ring while your hand misses the strings.",
  },
  {
    "id": "sunshine",
    "name": "Sunshine detour",
    "bpm": 104,
    "meter": 4,
    "best": "island",
    "options": ["eighths", "waltz", "island", "steady"],
    "hear":
        "Listen for notes between the main beats, especially after 2 and 3.",
    "why": "Island bounce echoes the offbeat melody. The gap on 3 lets the following upstroke stand out.",
    "rest": "Miss the strings after 1 and on 3. A skipped stroke is not a stopped hand or a fully silent song.",
  },
  {
    "id": "lantern",
    "name": "Lantern dance",
    "bpm": 90,
    "meter": 3,
    "best": "waltz",
    "options": ["island", "steady", "waltz", "eighths"],
    "hear": "The strong bass comes back every three beats: ONE-two-three.",
    "why": "Three-beat sway resets with the bass every three beats. Four-beat patterns drift across these bar lines.",
    "rest": "Leave the “ands” empty and let each chord ring. Keep the return upstroke light and silent.",
  },
  {
    "id": "spark",
    "name": "Little spark",
    "bpm": 112,
    "meter": 4,
    "best": "eighths",
    "options": ["steady", "eighths", "chuck", "waltz"],
    "hear": "The melody moves evenly on both the numbers and the “ands”.",
    "why": "Down-up flow matches this busy eighth-note melody. Keep the upstrokes light so it does not sound heavy.",
    "rest": "There are no skipped slots in this version. Try skipping some “ands” to hear how a simpler accompaniment changes the feel.",
  },
  {
    "id": "backbeat",
    "name": "Pocket groove",
    "bpm": 96,
    "meter": 4,
    "best": "chuck",
    "options": ["waltz", "chuck", "island", "steady"],
    "hear": "The melody is bouncy; try adding a short percussive accent on 2 and 4.",
    "why": "Muted backbeat is our suggested arrangement: chucks on 2 and 4 add a percussive contrast to the ringing melody.",
    "rest": "Skip the “and” after 1 and the downstroke on 3. X on 2 and 4 is a muted hit, not an empty slot.",
  },
];

// Timing and stroke direction are independent in the free rhythm lab.
const labStrokeCycle = ['D', 'U', 'X', '-'];
String nextLabStroke(String current) =>
    labStrokeCycle[(labStrokeCycle.indexOf(current) + 1) % labStrokeCycle.length];
