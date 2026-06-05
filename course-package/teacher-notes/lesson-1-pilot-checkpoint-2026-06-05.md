# Lesson 1 Pilot Checkpoint - 2026-06-05

## Status

Lesson 1, **Undo the Equation**, is the approved working pilot pattern to show another teacher for feedback. Baptiste reported that a test student completed and submitted Lesson 1.

Do not build the other 19 lessons until this Lesson 1 pattern is reviewed by the other teacher and accepted or revised.

## Lesson 1 Structure To Replicate

Default pacing: **60 minutes** unless Baptiste asks for a different target.

1. **Lesson Hero**
   - Title, time estimate, student-friendly explanation, California Common Core Math Standards, real-world application, and Lesson Goal.
   - Use California-style standards codes such as `A-REI.1`, `A-REI.3`, and `A-CED.1`.

2. **Overview Video**
   - Big-picture video before the first problem.
   - Locally dropped videos need web compression plus poster image.

3. **Overview Reflection**
   - One open-ended thought question directly below the overview video.
   - AI/rubric graded, not keyword-only graded.

4. **Lesson Vocabulary**
   - Compact definitions for math terms students need before problem-solving.

5. **Quick Start**
   - Simple conceptual warm-up, not a full problem.

6. **Contextual Video Questions**
   - Questions appear directly below the video.
   - Use transcript-verified questions when a transcript is available.

7. **Worked Example / Mini-Lesson**
   - Shows the equation-solving process with clear steps and a common mistake.

8. **Big-Concept Infographic**
   - Explains the core process visually.
   - Important math/text should be page-rendered, not baked into generated art.

9. **Hands-On Manipulative**
   - Students interact with the math choice, not just watch animation.
   - Lesson 1 uses an operation bank with distractors: students choose the inverse operation, then the board updates.

10. **Real-World Problem With Image**
    - Every real-world scenario should include supporting imagery.
    - Numbers, equations, and required text stay in page HTML for reliability.

11. **Retryable Practice**
    - Students can change an answer and click `Update Answer`.
    - Updated answers overwrite previous saved answers and scores.
    - Use one button only: `Submit Answer` before first save, `Update Answer` after save.

12. **Exit Check**
    - Final evidence for the lesson.
    - Exit-check questions lock after submission.
    - If the exit check is weak or below threshold, teacher dashboard flags review/remediation.

13. **Finish Line**
    - Separate `What you learned` from `Are you ready for the next lesson?`.
    - Bonus challenge is optional and must not give away the answer in the placeholder.

## Grading And Saving Rules

- Objective math answers use deterministic grading.
- Written explanations use AI rubric grading when the backend is available.
- Practice is for learning and can be updated.
- Exit-check responses are final unless the teacher resets or overrides.
- Answers save as students check them, so students can leave and return mid-lesson.
- Teacher previews must not save fake student work.
- Teacher work samples need individual regrade/override controls, not one mass regrade.

## Dashboard And Data Rules

- Gradebooks must be scoped by `course_id = caaspp-math-11`.
- Do not load CAASPP rosters from global `profiles`; that caused Driver's Ed students to appear in the CAASPP gradebook.
- Shared Supabase is acceptable only with course-scoped tables and enrollments.
- Future AI teacher insights should come from saved per-question responses, not static dashboard cards.
- When more students submit work, use the saved response data for trends, common misses, small-group suggestions, and remediation recommendations.
- Use one `Add Account` button with a role selector. Do not add a separate `Add Teacher` panel unless it has real teacher-management value.
- For scale, keep the top gradebook as a 20-lesson grid. The detailed section table should be an `Active Lesson Detail` panel for the selected lesson, not a breakdown of every lesson at once.
- The teacher insight panel should be named/actionable: `Follow-Up And Class Patterns`. It should first show students needing follow-up, then early class patterns from saved responses.
- Work samples need the student name, course name, lesson number/title, last activity, and a grade line like `24/32 - 75% - Needs Follow-Up`.
- If a student passes overall but has a weak exit check, keep the lesson score visible and still flag teacher follow-up.

## Critical Failures To Avoid

- Do not put builder/meta language on student pages.
- Do not expose gradebook or teacher previews on student login pages.
- Do not use the longer `HSA.REI.A.1` style in the student-facing California standards display.
- Do not use a separate retry icon/button; it confused the workflow.
- Do not put an answer in the placeholder text for a challenge question.
- Do not make hands-on math activities tell students exactly what to drag.
- Do not approve generated graphics without opening and checking them visually.
- Do not rely on GitHub Pages for AI grading or Study Buddy; static hosting cannot hide API keys.
- Do not let teacher/admin lesson previews save as student submissions.
- Do not assume 45 minutes is enough for this lesson pattern; use 60 minutes by default.

## Known Open Items

- Confirm the submitted test student's work appears correctly in the teacher gradebook and work-sample page.
- Confirm teacher reset password works in the deployed/backend environment.
- Deploy to Vercel or another backend-capable host before sharing AI grading/Study Buddy as a live public link.
- After teacher feedback, build Lessons 2-5 using the same structure before expanding to Modules 2-4.
