# Grading Policy

## Core Rule

Use deterministic grading whenever the answer can be checked reliably by code. Use AI only for reasoning quality, explanation, error analysis, and modeling.

## Deterministic Grading

Use for:

- multiple choice
- numeric answers
- simple table values
- selected equation models
- inequality graph choices
- function evaluations

## AI Rubric Grading

Use for:

- explaining inverse operations
- explaining inequality boundaries
- error analysis
- slope/intercept meaning in context
- modeling explanations
- rounding or practicality explanations

AI grading must return:

```json
{
  "score": 0,
  "maxScore": 0,
  "rubricMatches": [],
  "missingRequirements": [],
  "feedbackToStudent": "",
  "needsTeacherReview": false,
  "confidence": "high"
}
```

## Teacher Review Triggers

Send to teacher review when:

- AI confidence is low.
- Score is borderline.
- Student explanation is mathematically creative but hard to classify.
- Student gives the right number with a wrong explanation.
- Student gives a practical rounding answer without enough justification.
- Response includes private or concerning information.

## Feedback Tone

Feedback should name the next move. Avoid vague comments like "try harder" or "incorrect."

Good feedback:

"Your equation is set up correctly. The missing step is explaining why 22.5 tickets has to round up to 23, since tickets are whole items."

