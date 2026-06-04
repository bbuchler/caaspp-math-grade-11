# CAASPP Math Prep Course - Grade 11

This repository contains a pilot course package for an 11th grade CAASPP mathematics prep course.

## Preview

Static preview:

```text
course-package/preview.html
```

When served through a local web server, the preview loads the five Module 1 lesson JSON files and shows the student-facing flow.

AI-enabled local preview:

```text
C:\Users\bbuchler\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe scripts\local-ai-preview-server.js
```

Then open:

```text
http://127.0.0.1:8766/course-package/preview.html
```

The AI-enabled preview uses `/api/chat` and `/api/grade`, which require `GEMINI_API_KEY` in `.env` or the deployment environment. The `.env` file is ignored by git and should not be committed.

Teacher dashboard preview:

```text
http://127.0.0.1:8766/course-package/teacher-dashboard.html
```

The student course and teacher dashboard are separate areas. The teacher dashboard includes gradebook-style lesson links that open student lesson previews.

## Current Package

- `course-package/source-lock.md` - source list and open questions
- `course-package/course-brief.md` - course purpose and constraints
- `course-package/course-map.md` - Week 1 objective map
- `course-package/lessons/` - five lesson JSON files
- `course-package/media/` - video and infographic plan
- `course-package/assessments/` - quiz bank and rubrics
- `course-package/ai/` - Study Buddy and grading rules
- `course-package/teacher-dashboard.html` - static teacher dashboard preview
- `course-package/qa-report.md` - readiness and known risks

## Note

The original teacher-provided PDFs are intentionally ignored by git for now. The shareable course package is included; source PDFs can be added later if the repository is private and approved for that use.
