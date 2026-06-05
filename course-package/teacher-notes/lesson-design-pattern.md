# CAASPP Math Lesson Design Pattern

Use this pattern for Lesson 1 first, then repeat it for the remaining 19 lessons if the pilot teacher likes the flow.

## Student Lesson Flow

1. **Lesson Hero**
   - Names the lesson, time estimate, why the skill matters, and the learning target.

2. **Overview Video**
   - A short big-picture video that frames the skill before students start problem solving.

3. **Overview Reflection**
   - One open-ended question directly under the overview video.
   - Goal: get students to explain the main idea in their own words.
   - Grading: AI rubric or teacher review, not brittle keyword grading.

4. **Lesson Vocabulary**
   - Short scaffold for terms students need before the math gets harder.
   - Usually collapsible or compact so it helps without taking over the lesson.

5. **Quick Start**
   - A simple conceptual check, not a full problem.
   - Goal: lower the barrier and activate the core idea.
   - Grading: retryable.

6. **Contextual Video Questions**
   - Questions sit directly below the video they belong to.
   - Goal: students answer while watching instead of taking vague notes.
   - Grading: objective answers are deterministic; explanations use AI rubric feedback.

7. **Worked Example Or Mini-Lesson**
   - Shows the math move clearly before students practice.
   - For math notation, use rendered fractions/equations instead of slash text when readability matters.

8. **Big-Concept Infographic**
   - Gives students a visual explanation of the main concept, process, or common mistake.
   - Use page-rendered math/text for important labels so the visual does not depend on AI-generated text accuracy.
   - Place it near the concept it explains, not as decoration.

9. **Hands-On Manipulative**
   - Interactive activity for students who need to see or move the math.
   - It must show the actual quantities being changed; avoid abstract or confusing "magic button" moves.
   - Grading: practice/learning only unless a specific answer is submitted.

10. **Real-World Problem**
   - Uses a scenario students can picture.
   - Every real-world problem should have a supporting image or visual context.
   - Images can create context, but critical numbers/equations should be page text.
   - Grading: can combine deterministic math with AI-graded explanation.

11. **Retryable Practice**
   - Students can try again until they understand.
   - Goal: learning during the lesson, not punishment for the first miss.

12. **Exit Check**
   - Short final evidence for the lesson.
   - Students do not retry these automatically.
   - If the exit check is below 70%, the teacher dashboard should flag the student for review/remediation.

13. **Finish Line**
   - Celebrates completion, names what students learned, gives a simple "ready/need practice" message, offers an optional challenge, then submits the lesson.

## Grading Rules

- Practice questions are retryable.
- Exit-check questions lock after submission.
- Objective questions use deterministic grading.
- Open explanations use AI rubric feedback when the backend is available.
- Teacher dashboard must allow teacher override and individual regrade, not a mass regrade that changes everything at once.
- A student can still pass the lesson overall if they did well on the full lesson, but a weak exit check should be visible to the teacher as a remediation flag.

## Teacher Dashboard Signal

For the pilot, the dashboard should show:

- lesson score and completion
- work sample by question
- teacher override
- individual AI regrade
- review flag when an AI response or exit check needs attention

Later, when there are more students, use the same saved question data to add:

- class trends
- most-missed questions
- small-group suggestions
- backup/remediation lessons
