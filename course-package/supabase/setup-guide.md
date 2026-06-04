# Supabase Setup For CAASPP Math

## Recommendation

Use the existing Driver's Ed Supabase project as the shared Altus Courses backend. It already has the account/dashboard pattern, it has fewer active students than photography, and it can be expanded to hold CAASPP Math without touching the live Photography project.

Photography is still the best model for the workflow, but it does not need to be the database host. Leave Photography's Supabase project alone while students are actively using it.

The safer migration is:

```text
course-package/supabase/shared-altus-courses-migration.sql
```

Do not paste `math-pilot-schema.sql` into the photography project. That file is for a brand-new Supabase project and includes profile/auth setup that should not replace the existing photography setup.

## What Baptiste Does

1. Open the existing Driver's Ed Supabase project.
2. Open the SQL Editor.
3. Paste and run `course-package/supabase/shared-altus-courses-migration.sql`.
4. Copy these values from Supabase Project Settings -> API:
   - Project URL
   - anon public key
   - service_role key
5. Send Codex the Project URL and anon public key. Put the service role key only in `.env` or Vercel environment variables; do not paste it into public files.

## Safety Rule

Driver's Ed is still a live course, so do not run course-sharing migrations until:

1. The current course tables have been exported or backed up.
2. The migration has been reviewed as additive only.
3. The migration does not alter existing course tables, existing auth triggers, or existing RLS policies.
4. There is a rollback plan for the new `course_*` tables if the pilot is abandoned.

## Long-Term Shape

The Driver's Ed Supabase project can become the shared backend for:

- Driver's Ed
- CAASPP Math
- Future course packages

Photography can stay on its current project unless there is a strong reason to move it later.

## What Codex Does After That

1. Add `course-package/js/supabase-config.js` with the project URL and anon key.
2. Wire student Lesson 1 submissions into `course_question_responses`.
3. Wire the teacher gradebook to `course_lesson_score_summary`.
4. Wire the work sample page to `course_question_responses`.
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

The shared migration also adds future-ready tables for:

- `course_question_catalog` - the question bank metadata across any course
- `course_concepts` - skills or concepts such as inverse operations, sourcing evidence, thesis writing, etc.
- `course_concept_trends` - aggregated concept-level trends
- `course_remediation_resources` - backup lessons, alternate videos, scaffolded practice, or challenge work
- `course_small_groups` and `course_small_group_members` - teacher-created or trend-suggested tutoring groups

## V1 Boundary

Lesson 1 should become fully real first. Lessons 2-20 can stay visible as upcoming columns until the Lesson 1 student flow, work sample, gradebook, AI grading, and teacher controls feel right.
