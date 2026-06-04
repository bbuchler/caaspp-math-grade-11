# Answer Key And AI Grading Model

## Short Version

The AI should not guess the answer.

The course package stores the answer key, rubric, expected elements, and feedback. The app uses those fields to grade deterministic items directly and to guide AI grading for open responses.

## Where Answers Live

Answers live in the lesson JSON and quiz bank.

Examples:

- Multiple choice: `answer: "B"`
- Numeric answer: `answer: 21`
- Table answer: `answer: [4, 7, 10]`
- Open response: `rubricId: "math-explanation-3"` plus optional `expectedElements`

## How The App Should Grade

### Deterministic First

Use code for anything with a clear answer:

- multiple choice
- numeric answers
- function evaluations
- selected graph descriptions
- table values
- simple model choices

The app checks the student's answer against the stored answer and shows the stored feedback.

### AI Second

Use AI only when judgment is needed:

- explanation quality
- error analysis
- modeling write-up
- practical interpretation
- rounding justification

The AI receives:

- the student response
- the prompt
- the rubric
- expected elements when available
- the current lesson context

The AI should return structured JSON with score, feedback, missing requirements, confidence, and teacher-review flag.

Current V1 endpoint:

```text
POST /api/grade
```

The local preview calls this endpoint for rubric-graded short answers when the course is served by `scripts/local-ai-preview-server.js` or deployed to Vercel with `GEMINI_API_KEY`.

## Important Boundary

For active graded checks, the Study Buddy should not receive the final answer key in a way that lets it simply reveal answers. It should receive a student-safe context pack:

- learning target
- teaching text
- worked examples
- common mistakes
- allowed similar-practice patterns
- vocabulary
- rubric language without final answer reveal

Teacher review tools can receive answer keys. Student tutoring tools should not casually expose them.

## Video Question Accuracy

The Lesson 01 video questions are transcript-verified using the teacher-provided transcript for the YouTube/Khan video "Level one linear equations."

The remaining V1 video questions are topic-aligned to the selected videos and lesson objectives. They are not yet transcript-locked.

Before classroom release, each video question should be one of these:

1. Transcript-verified: based on a checked transcript or exact video moment.
2. Lesson-anchored: based on the lesson's own teaching text, with the video used as reinforcement.

Do not ask a question that depends on an unverified timestamp or a detail that may not appear in the video.

## Recommended V1 Rule

For the first release, make the video questions mostly lesson-anchored:

- "What operation undoes multiplication?"
- "Should x > 5 use an open or closed point?"
- "What does the number inside f(3) mean?"

Those are safe because the lesson itself teaches the answer. Later, if we pull full transcripts through Reel or another source, we can make tighter timestamp questions.
