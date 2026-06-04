# Supabase Setup For CAASPP Math

## Recommendation

Create a new Supabase project for this course instead of reusing photography. The app can reuse the same pattern, but a separate project keeps student math records, teacher testing, and future CAASPP analytics clean.

## What Baptiste Does

1. Create a new Supabase project.
2. Open the SQL Editor.
3. Paste and run `course-package/supabase/math-pilot-schema.sql`.
4. Copy these values from Supabase Project Settings -> API:
   - Project URL
   - anon public key
   - service_role key
5. Send Codex the Project URL and anon public key. Put the service role key only in `.env` or Vercel environment variables; do not paste it into public files.

## What Codex Does After That

1. Add `course-package/js/supabase-config.js` with the project URL and anon key.
2. Wire student Lesson 1 submissions into `student_question_responses`.
3. Wire the teacher gradebook to `lesson_score_summary`.
4. Wire the work sample page to `student_question_responses`.
5. Wire reset password, create account, and reset lesson through serverless API functions using `SUPABASE_SERVICE_ROLE_KEY`.
6. Push the working version to GitHub and deploy it somewhere server-backed, such as Vercel, because GitHub Pages cannot safely hold API keys.

## Why This Makes AI Trends Work

Each student answer is stored as its own row with:

- lesson id
- question id
- answer
- score
- max score
- feedback
- AI confidence
- teacher review flag
- concept tags
- misconception tags

That lets the teacher dashboard show real trends, such as:

- which questions were missed most often
- which students need a small group
- which answers need teacher review
- which concept should trigger a scaffolded backup lesson

## V1 Boundary

Lesson 1 should become fully real first. Lessons 2-20 can stay visible as upcoming columns until the Lesson 1 student flow, work sample, gradebook, AI grading, and teacher controls feel right.
