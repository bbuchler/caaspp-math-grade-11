# Teacher Dashboard Plan

## Recommendation

Use the same production dashboard pattern as the existing CertReady-style courses. Do not build a separate math-only teacher system.

The CAASPP math course package should act as the content source: lesson JSON, answer keys, rubrics, media, and Study Buddy context. The production app should handle rosters, teachers, passwords, progress, grading records, resets, and reporting.

## What Teachers Should See

- Course overview with four modules and about 20 lessons.
- Week/module drill-down, similar to photography and driver education.
- A student roster with add student, add teacher, reset password, and deactivate controls.
- Per-student progress showing lesson status, exit-check score, rubric flags, and last activity.
- Per-lesson grade view showing objective answers, open responses, AI rubric notes, and teacher override.
- Reset controls for a lesson attempt, a quiz/check, or a full course restart.
- Teacher review queue for low-confidence AI grading, weak explanations, off-topic responses, or possible copying.

## Math-Specific Additions

- Objective math answers grade instantly from the answer key.
- Numeric answers should allow equivalent formats when needed, such as fractions, decimals, or simplified forms.
- Written math explanations should be rubric-graded, not treated as simple exact-match answers.
- The Study Buddy should know the current lesson, visible section, worked example, and common mistakes.
- The Study Buddy should not receive hidden answer keys for active student questions.

## Student Record Shape

Each student attempt should store:

- student id
- course id
- module id
- lesson id
- question id
- submitted answer
- deterministic score when available
- rubric score when available
- AI confidence when available
- teacher override when applied
- timestamp

## V1 Boundary

The current `preview.html` is a student preview only. It does not save progress, manage users, reset passwords, or call AI.

The production version should connect this course package to the existing dashboard/auth/grading architecture so teachers get the same management tools they already expect.
