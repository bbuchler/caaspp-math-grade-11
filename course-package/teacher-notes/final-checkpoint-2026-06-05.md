# CAASPP Math Course Checkpoint - 2026-06-05

## Current State

- The live Vercel course is deployed at `https://caaspp-math-grade-11.vercel.app`.
- Lesson 1, **Undo the Equation**, is the only fully built lesson.
- Lessons 2-20 are visible in the gradebook/course shape but should be treated as placeholders until content is supplied.
- The course uses the shared Driver's Ed / Altus Courses Supabase backend with `course_id = caaspp-math-11`.
- Teacher and student dashboards are separate authenticated areas.
- The teacher dashboard supports the core Photography-style operations: add account, teacher accounts section, welcome email regeneration, reset password, course-scoped remove/reactivate, class sections, gradebook, work samples, and print/export.

## Lesson 1 Structure To Preserve

Each future lesson should follow this structure unless the content clearly requires a change:

1. Lesson hero with California standards, real-world value, and lesson goal.
2. Overview video, usually NotebookLM or teacher-created.
3. Overview reflection directly under the video.
4. Lesson vocabulary.
5. Simple conceptual quick start.
6. Contextual video questions below the core video.
7. Worked example or mini-lesson.
8. Infographic or visual explanation of the big idea.
9. Hands-on / kinesthetic practice.
10. Real-world task with supporting imagery.
11. Retryable practice questions.
12. One-attempt exit check.
13. Finish line, submit button, and optional extension.

## Grading Rules

- Practice questions are for learning and should be retryable.
- Retryable questions use one button: `Submit Answer` before saving and `Update Answer` after saving.
- Updated practice answers overwrite the prior answer and score.
- Exit-check questions are one attempt because they are final lesson evidence.
- A student can pass the lesson overall with 70% or higher even if the exit check is weak.
- If the exit check is below 70%, the teacher dashboard should flag the student for follow-up/remediation.
- Objective math should be deterministic where possible.
- AI should grade explanations and reasoning with a rubric, partial credit, and feedback.
- Teachers need individual question override and individual AI regrade, not a mass regrade.

## Dashboard Rules Learned

- Do not reinvent the teacher dashboard if Photography already has a working pattern.
- Teacher account management must be visible, not hidden in the add-account modal.
- A proper teacher dashboard needs:
  - 20-lesson gradebook grid
  - student search
  - class and teacher filters
  - class sections
  - teacher accounts section
  - welcome email regeneration
  - reset password
  - course-scoped remove/reactivate
  - work sample links
  - print/export
  - follow-up/action queue from real saved data
- Work samples should be clean artifacts, not editing screens.
- Work samples should show course name, student name, lesson number/title, last activity, overall score, letter grade, section scores, student answers, and feedback.
- Teacher override controls should be tucked away on screen and hidden from print.
- Follow-up flags belong in the dashboard/action queue, not in the printable grade line.

## Backend Rules Learned

- Shared Supabase is fine if every table and query is course-scoped.
- Never load CAASPP rosters from global `profiles`.
- Course rosters should come from `course_enrollments` filtered by `course_id` and active status.
- Class filters should be backed by real tables:
  - `course_class_sections`
  - `course_class_teachers`
  - `course_class_students`
- Remove/reactivate should update only CAASPP course enrollment and CAASPP class memberships. It should not delete auth users or touch other courses.
- Passwords cannot be read back after creation. The welcome email can show the password only immediately after account creation or after a teacher manually enters/resets it.

## Media And Visual Rules Learned

- Use YouTube embed URLs for core videos when direct platform embeds do not work.
- NotebookLM overview videos work well as lesson openers when they are short and placed before the reflection.
- Important equations, numbers, and instructions should be page-rendered text, not baked into generated images.
- Real-world examples should have imagery to make the problem concrete.
- Infographics should be visually checked before approval; generated SVG/text often overflows or looks low quality.
- Math notation should render fractions vertically when readability matters.

## Known Failures To Avoid

- Do not put meta-builder language on student pages.
- Do not say "teacher should..." or "AI should..." in student-facing lessons.
- Do not present fake dashboard trends from one student as real class patterns.
- Do not show unrelated Driver's Ed or other course students in the CAASPP gradebook.
- Do not claim Lexile/adaptive reading support unless the feature is actually built.
- Do not use raw SQL to create Supabase Auth users unless absolutely necessary; use Admin API when possible.
- Do not rewrite Vercel root to `course-package/index.html`; redirect instead, or relative scripts break.
- Do not create a teacher email that is just credentials. Use a rich-text email with course purpose, login, basic workflow, and Teacher Guide reference.

## Next Best Work

1. Have Matt review Lesson 1 as the math expert.
2. Confirm Matt can log in, create a test student, complete Lesson 1, and see the work sample.
3. Ask Matt whether the lesson structure should remain the template for Lessons 2-20.
4. If yes, collect content for Lessons 2-20:
   - concept/standard
   - YouTube core video
   - optional NotebookLM overview video
   - vocabulary
   - real-world scenario
   - hands-on activity idea
   - practice questions
   - exit check questions
5. After more students submit, revisit teacher insights so class patterns and remediation are based on real data.
