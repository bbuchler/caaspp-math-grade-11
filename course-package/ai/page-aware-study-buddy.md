# Page-Aware Study Buddy Architecture

## Goal

The Study Buddy should know what lesson page the student is on and help with that exact content.

## Recommended Data Flow

When the student opens Study Buddy, the app sends a student-safe context pack:

```json
{
  "course": "CAASPP Math Success Academy",
  "lessonId": "03",
  "lessonTitle": "Lines Tell Stories",
  "learningTarget": "...",
  "visibleSection": "practice",
  "teachingText": "...",
  "workedExample": "...",
  "commonMistakes": ["..."],
  "studentQuestion": "...",
  "allowedHelp": [
    "explain the concept",
    "ask a guiding question",
    "make a similar problem",
    "help revise reasoning"
  ],
  "blockedHelp": [
    "give final graded answer",
    "write the constructed response"
  ]
}
```

## What The Study Buddy Can See

Safe:

- current lesson title and learning target
- visible teaching text
- worked example
- common mistake notes
- student's current draft answer if the student asks for feedback
- rubric language for explanation quality

Use caution:

- exact answer keys for active graded checks
- teacher-only notes
- full quiz bank

Never send:

- learner identifiers
- gradebook data
- protected support records
- unrelated private student information

## Student Help Pattern

1. Identify the current skill.
2. Ask one guiding question.
3. If the student tries, give feedback on the step.
4. If the student is stuck, show a similar example with different numbers.
5. Ask the student to return to the original problem.

## Example

Student asks:

"I don't get this one."

Study Buddy response:

"This is a slope/intercept question. First find the number that repeats for each ticket sold. In the model R = 12s + 50, which number changes the revenue for each 1 shirt?"

## API Shape

Future endpoint:

```text
POST /api/study-buddy
```

Request:

```json
{
  "lessonContext": {},
  "visibleQuestion": {},
  "studentMessage": "",
  "studentDraft": ""
}
```

Response:

```json
{
  "reply": "",
  "suggestedNextStep": "",
  "needsTeacherHelp": false
}
```

