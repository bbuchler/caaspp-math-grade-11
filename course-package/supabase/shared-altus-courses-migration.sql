-- CAASPP Math Prep Course - Shared Supabase Migration
-- Use this when adding CAASPP Math to an existing course Supabase project.
-- Recommended first target: the lower-stakes Driver's Ed project as a sandbox.
-- Do not run this first in the live Photography project while active students
-- are using it.
--
-- This intentionally DOES NOT recreate public.profiles, auth triggers,
-- existing course-specific tables, existing RLS policies, or existing helper
-- functions. It reuses the existing profiles/auth setup and adds shared
-- course tables keyed by course_id.

create extension if not exists "pgcrypto";

-- Courses can include photography, driver's ed, CAASPP math, and future courses.
create table if not exists public.courses (
  id text primary key,
  title text not null,
  subject text,
  status text not null default 'active' check (status in ('active', 'pilot', 'archived')),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

insert into public.courses (id, title, subject, status)
values ('caaspp-math-11', 'CAASPP Math Success Academy - Grade 11', 'Math', 'pilot')
on conflict (id) do update set
  title = excluded.title,
  subject = excluded.subject,
  status = excluded.status,
  updated_at = now();

create table if not exists public.course_lessons (
  id uuid default gen_random_uuid() primary key,
  course_id text references public.courses(id) on delete cascade not null,
  lesson_number int not null,
  module_number int not null,
  title text not null,
  status text not null default 'upcoming' check (status in ('active', 'upcoming', 'hidden')),
  total_questions int default 0,
  total_points numeric(6,2) default 0,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(course_id, lesson_number)
);

-- Optional question catalog. Student responses still store prompt snapshots,
-- but this table gives the teacher dashboard a stable place to track standards,
-- concepts, difficulty, and item design across any course.
create table if not exists public.course_question_catalog (
  id uuid default gen_random_uuid() primary key,
  course_id text references public.courses(id) on delete cascade not null,
  lesson_number int not null,
  section_id text not null,
  section_title text,
  question_id text not null,
  question_type text not null,
  prompt text not null,
  max_score numeric(6,2) default 1,
  concept_tags text[] default '{}',
  standard_refs text[] default '{}',
  skill_level text default 'core' check (skill_level in ('foundation', 'core', 'challenge')),
  item_purpose text default 'practice' check (item_purpose in ('launch', 'video_check', 'practice', 'exit_check', 'performance_task', 'remediation')),
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(course_id, lesson_number, question_id)
);

create table if not exists public.course_concepts (
  id uuid default gen_random_uuid() primary key,
  course_id text references public.courses(id) on delete cascade not null,
  concept_tag text not null,
  title text not null,
  description text,
  subject text,
  grade_band text,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(course_id, concept_tag)
);

insert into public.course_concepts (course_id, concept_tag, title, description, subject, grade_band)
values
  ('caaspp-math-11', 'linear_equations', 'Linear Equations', 'Solve and interpret one-step and two-step linear equations.', 'Math', '11'),
  ('caaspp-math-11', 'inverse_operations', 'Inverse Operations', 'Undo operations while keeping both sides balanced.', 'Math', '11'),
  ('caaspp-math-11', 'coefficient', 'Coefficient Meaning', 'Identify the number multiplying a variable and use it to isolate the variable.', 'Math', '11'),
  ('caaspp-math-11', 'checking_solutions', 'Checking Solutions', 'Substitute a solution back into the original equation to verify it.', 'Math', '11')
on conflict (course_id, concept_tag) do update set
  title = excluded.title,
  description = excluded.description,
  subject = excluded.subject,
  grade_band = excluded.grade_band,
  updated_at = now();

insert into public.course_lessons (course_id, lesson_number, module_number, title, status, total_questions, total_points)
values
  ('caaspp-math-11', 1, 1, 'Undo the Equation', 'active', 17, 29),
  ('caaspp-math-11', 2, 1, 'Inequalities Are Ranges', 'upcoming', 0, 0),
  ('caaspp-math-11', 3, 1, 'Lines Tell Stories', 'upcoming', 0, 0),
  ('caaspp-math-11', 4, 1, 'Slope, Intercepts, and Meaning', 'upcoming', 0, 0),
  ('caaspp-math-11', 5, 1, 'Function Notation and Mini Performance Task', 'upcoming', 0, 0),
  ('caaspp-math-11', 6, 2, 'Module 2 Lesson 6', 'upcoming', 0, 0),
  ('caaspp-math-11', 7, 2, 'Module 2 Lesson 7', 'upcoming', 0, 0),
  ('caaspp-math-11', 8, 2, 'Module 2 Lesson 8', 'upcoming', 0, 0),
  ('caaspp-math-11', 9, 2, 'Module 2 Lesson 9', 'upcoming', 0, 0),
  ('caaspp-math-11', 10, 2, 'Module 2 Lesson 10', 'upcoming', 0, 0),
  ('caaspp-math-11', 11, 3, 'Module 3 Lesson 11', 'upcoming', 0, 0),
  ('caaspp-math-11', 12, 3, 'Module 3 Lesson 12', 'upcoming', 0, 0),
  ('caaspp-math-11', 13, 3, 'Module 3 Lesson 13', 'upcoming', 0, 0),
  ('caaspp-math-11', 14, 3, 'Module 3 Lesson 14', 'upcoming', 0, 0),
  ('caaspp-math-11', 15, 3, 'Module 3 Lesson 15', 'upcoming', 0, 0),
  ('caaspp-math-11', 16, 4, 'Module 4 Lesson 16', 'upcoming', 0, 0),
  ('caaspp-math-11', 17, 4, 'Module 4 Lesson 17', 'upcoming', 0, 0),
  ('caaspp-math-11', 18, 4, 'Module 4 Lesson 18', 'upcoming', 0, 0),
  ('caaspp-math-11', 19, 4, 'Module 4 Lesson 19', 'upcoming', 0, 0),
  ('caaspp-math-11', 20, 4, 'Module 4 Lesson 20', 'upcoming', 0, 0)
on conflict (course_id, lesson_number) do update set
  module_number = excluded.module_number,
  title = excluded.title,
  status = excluded.status,
  total_questions = excluded.total_questions,
  total_points = excluded.total_points,
  updated_at = now();

-- Enrollment controls which students/teachers see this course.
create table if not exists public.course_enrollments (
  id uuid default gen_random_uuid() primary key,
  course_id text references public.courses(id) on delete cascade not null,
  user_id uuid references public.profiles(id) on delete cascade not null,
  role text not null default 'student' check (role in ('student', 'teacher', 'staff', 'admin')),
  status text not null default 'active' check (status in ('active', 'inactive', 'completed')),
  created_by uuid references public.profiles(id),
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(course_id, user_id)
);

create table if not exists public.course_lesson_attempts (
  id uuid default gen_random_uuid() primary key,
  course_id text references public.courses(id) on delete cascade not null,
  student_id uuid references public.profiles(id) on delete cascade not null,
  lesson_number int not null,
  status text default 'not_started' check (status in ('not_started', 'in_progress', 'submitted', 'graded', 'reset')),
  score numeric(6,2) default 0,
  max_score numeric(6,2) default 0,
  percent numeric(5,2) default 0,
  needs_teacher_review boolean default false,
  started_at timestamptz,
  submitted_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(course_id, student_id, lesson_number)
);

-- One row per question. This powers work samples, AI review queue, trends, and small groups.
create table if not exists public.course_question_responses (
  id uuid default gen_random_uuid() primary key,
  course_id text references public.courses(id) on delete cascade not null,
  student_id uuid references public.profiles(id) on delete cascade not null,
  lesson_number int not null,
  section_id text not null,
  section_title text,
  question_id text not null,
  question_type text not null,
  prompt text not null,
  answer text,
  score numeric(6,2) default 0,
  max_score numeric(6,2) default 1,
  feedback text,
  grading_method text not null default 'deterministic' check (grading_method in ('deterministic', 'ai_rubric', 'teacher_override')),
  ai_confidence numeric(4,3),
  needs_teacher_review boolean default false,
  concept_tags text[] default '{}',
  misconception_tags text[] default '{}',
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(course_id, student_id, lesson_number, question_id)
);

create table if not exists public.course_teacher_overrides (
  id uuid default gen_random_uuid() primary key,
  response_id uuid references public.course_question_responses(id) on delete cascade not null,
  teacher_id uuid references public.profiles(id) not null,
  original_score numeric(6,2),
  override_score numeric(6,2) not null,
  feedback text,
  created_at timestamptz default now()
);

create table if not exists public.course_remediation_assignments (
  id uuid default gen_random_uuid() primary key,
  course_id text references public.courses(id) on delete cascade not null,
  student_id uuid references public.profiles(id) on delete cascade not null,
  lesson_number int not null,
  assigned_by uuid references public.profiles(id),
  concept_tag text not null,
  level text not null default 'scaffolded' check (level in ('scaffolded', 'same_level', 'challenge')),
  status text not null default 'assigned' check (status in ('assigned', 'completed', 'dismissed')),
  created_at timestamptz default now(),
  completed_at timestamptz
);

create table if not exists public.course_remediation_resources (
  id uuid default gen_random_uuid() primary key,
  course_id text references public.courses(id) on delete cascade not null,
  concept_tag text not null,
  level text not null default 'scaffolded' check (level in ('scaffolded', 'same_level', 'challenge')),
  title text not null,
  resource_type text not null default 'lesson' check (resource_type in ('lesson', 'video', 'practice_set', 'infographic', 'teacher_small_group', 'external_link')),
  url text,
  teacher_notes text,
  student_instructions text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.course_small_groups (
  id uuid default gen_random_uuid() primary key,
  course_id text references public.courses(id) on delete cascade not null,
  title text not null,
  concept_tag text not null,
  lesson_number int,
  status text not null default 'planned' check (status in ('planned', 'active', 'completed', 'dismissed')),
  created_by uuid references public.profiles(id),
  created_from text default 'teacher' check (created_from in ('teacher', 'trend', 'ai_suggestion')),
  notes text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.course_small_group_members (
  id uuid default gen_random_uuid() primary key,
  group_id uuid references public.course_small_groups(id) on delete cascade not null,
  student_id uuid references public.profiles(id) on delete cascade not null,
  reason text,
  status text not null default 'active' check (status in ('active', 'completed', 'removed')),
  created_at timestamptz default now(),
  unique(group_id, student_id)
);

create or replace view public.course_lesson_score_summary as
select
  ce.course_id,
  p.id as student_id,
  p.full_name,
  p.username,
  p.created_by,
  cl.lesson_number,
  cl.title as lesson_title,
  cl.status as lesson_status,
  coalesce(cla.status, 'not_started') as attempt_status,
  coalesce(cla.score, 0) as score,
  coalesce(cla.max_score, cl.total_points, 0) as max_score,
  coalesce(cla.percent, 0) as percent,
  coalesce(cla.needs_teacher_review, false) as needs_teacher_review,
  cla.updated_at as last_activity
from public.course_enrollments ce
join public.profiles p on p.id = ce.user_id and ce.role = 'student'
join public.course_lessons cl on cl.course_id = ce.course_id
left join public.course_lesson_attempts cla
  on cla.course_id = ce.course_id
  and cla.student_id = p.id
  and cla.lesson_number = cl.lesson_number;

create or replace view public.course_class_question_trends as
select
  course_id,
  lesson_number,
  question_id,
  max(prompt) as prompt,
  max(section_title) as section_title,
  count(*) as attempts,
  count(*) filter (where score < max_score) as needs_support,
  round(avg(case when max_score > 0 then score / max_score else 0 end) * 100, 1) as average_percent
from public.course_question_responses
group by course_id, lesson_number, question_id;

create or replace view public.course_concept_trends as
select
  course_id,
  lesson_number,
  concept_tag,
  count(*) as attempts,
  count(distinct student_id) as students_attempted,
  count(*) filter (where score < max_score) as needs_support,
  round(avg(case when max_score > 0 then score / max_score else 0 end) * 100, 1) as average_percent,
  count(*) filter (where needs_teacher_review) as teacher_review_count
from (
  select
    course_id,
    lesson_number,
    student_id,
    score,
    max_score,
    needs_teacher_review,
    unnest(case when array_length(concept_tags, 1) is null then array['uncategorized'] else concept_tags end) as concept_tag
  from public.course_question_responses
) tagged
group by course_id, lesson_number, concept_tag;

alter table public.courses enable row level security;
alter table public.course_lessons enable row level security;
alter table public.course_enrollments enable row level security;
alter table public.course_lesson_attempts enable row level security;
alter table public.course_question_responses enable row level security;
alter table public.course_teacher_overrides enable row level security;
alter table public.course_remediation_assignments enable row level security;
alter table public.course_question_catalog enable row level security;
alter table public.course_concepts enable row level security;
alter table public.course_remediation_resources enable row level security;
alter table public.course_small_groups enable row level security;
alter table public.course_small_group_members enable row level security;

-- Course-specific helper name so we do not overwrite any existing app helper.
create or replace function public.altus_courses_get_my_role()
returns text as $$
  select role from public.profiles where id = auth.uid();
$$ language sql security definer stable;

drop policy if exists "Signed in users can read active courses" on public.courses;
drop policy if exists "Signed in users can read course lessons" on public.course_lessons;
drop policy if exists "Signed in users can read question catalog" on public.course_question_catalog;
drop policy if exists "Teachers manage question catalog" on public.course_question_catalog;
drop policy if exists "Signed in users can read course concepts" on public.course_concepts;
drop policy if exists "Teachers manage course concepts" on public.course_concepts;
drop policy if exists "Users can read own enrollments" on public.course_enrollments;
drop policy if exists "Teachers can read course enrollments" on public.course_enrollments;
drop policy if exists "Teachers can manage course enrollments" on public.course_enrollments;
drop policy if exists "Students manage own course attempts" on public.course_lesson_attempts;
drop policy if exists "Teachers read course attempts" on public.course_lesson_attempts;
drop policy if exists "Teachers update course attempts" on public.course_lesson_attempts;
drop policy if exists "Students manage own course responses" on public.course_question_responses;
drop policy if exists "Teachers read course responses" on public.course_question_responses;
drop policy if exists "Teachers update course responses" on public.course_question_responses;
drop policy if exists "Teachers manage course overrides" on public.course_teacher_overrides;
drop policy if exists "Teachers manage remediation assignments" on public.course_remediation_assignments;
drop policy if exists "Signed in users can read remediation resources" on public.course_remediation_resources;
drop policy if exists "Teachers manage remediation resources" on public.course_remediation_resources;
drop policy if exists "Teachers manage small groups" on public.course_small_groups;
drop policy if exists "Teachers manage small group members" on public.course_small_group_members;
drop policy if exists "Students read own small group membership" on public.course_small_group_members;

create policy "Signed in users can read active courses"
  on public.courses for select
  using (auth.uid() is not null);

create policy "Signed in users can read course lessons"
  on public.course_lessons for select
  using (auth.uid() is not null);

create policy "Signed in users can read question catalog"
  on public.course_question_catalog for select
  using (auth.uid() is not null);

create policy "Teachers manage question catalog"
  on public.course_question_catalog for all
  using (public.altus_courses_get_my_role() in ('teacher', 'staff', 'admin'))
  with check (public.altus_courses_get_my_role() in ('teacher', 'staff', 'admin'));

create policy "Signed in users can read course concepts"
  on public.course_concepts for select
  using (auth.uid() is not null);

create policy "Teachers manage course concepts"
  on public.course_concepts for all
  using (public.altus_courses_get_my_role() in ('teacher', 'staff', 'admin'))
  with check (public.altus_courses_get_my_role() in ('teacher', 'staff', 'admin'));

create policy "Users can read own enrollments"
  on public.course_enrollments for select
  using (auth.uid() = user_id);

create policy "Teachers can read course enrollments"
  on public.course_enrollments for select
  using (public.altus_courses_get_my_role() in ('teacher', 'staff', 'admin'));

create policy "Teachers can manage course enrollments"
  on public.course_enrollments for all
  using (public.altus_courses_get_my_role() in ('teacher', 'staff', 'admin'))
  with check (public.altus_courses_get_my_role() in ('teacher', 'staff', 'admin'));

create policy "Students manage own course attempts"
  on public.course_lesson_attempts for all
  using (auth.uid() = student_id)
  with check (auth.uid() = student_id);

create policy "Teachers read course attempts"
  on public.course_lesson_attempts for select
  using (public.altus_courses_get_my_role() in ('teacher', 'staff', 'admin'));

create policy "Teachers update course attempts"
  on public.course_lesson_attempts for update
  using (public.altus_courses_get_my_role() in ('teacher', 'staff', 'admin'));

create policy "Students manage own course responses"
  on public.course_question_responses for all
  using (auth.uid() = student_id)
  with check (auth.uid() = student_id);

create policy "Teachers read course responses"
  on public.course_question_responses for select
  using (public.altus_courses_get_my_role() in ('teacher', 'staff', 'admin'));

create policy "Teachers update course responses"
  on public.course_question_responses for update
  using (public.altus_courses_get_my_role() in ('teacher', 'staff', 'admin'));

create policy "Teachers manage course overrides"
  on public.course_teacher_overrides for all
  using (public.altus_courses_get_my_role() in ('teacher', 'staff', 'admin'))
  with check (public.altus_courses_get_my_role() in ('teacher', 'staff', 'admin'));

create policy "Teachers manage remediation assignments"
  on public.course_remediation_assignments for all
  using (public.altus_courses_get_my_role() in ('teacher', 'staff', 'admin') or auth.uid() = student_id)
  with check (public.altus_courses_get_my_role() in ('teacher', 'staff', 'admin'));

create policy "Signed in users can read remediation resources"
  on public.course_remediation_resources for select
  using (auth.uid() is not null);

create policy "Teachers manage remediation resources"
  on public.course_remediation_resources for all
  using (public.altus_courses_get_my_role() in ('teacher', 'staff', 'admin'))
  with check (public.altus_courses_get_my_role() in ('teacher', 'staff', 'admin'));

create policy "Teachers manage small groups"
  on public.course_small_groups for all
  using (public.altus_courses_get_my_role() in ('teacher', 'staff', 'admin'))
  with check (public.altus_courses_get_my_role() in ('teacher', 'staff', 'admin'));

create policy "Teachers manage small group members"
  on public.course_small_group_members for all
  using (public.altus_courses_get_my_role() in ('teacher', 'staff', 'admin'))
  with check (public.altus_courses_get_my_role() in ('teacher', 'staff', 'admin'));

create policy "Students read own small group membership"
  on public.course_small_group_members for select
  using (auth.uid() = student_id);

create index if not exists idx_course_lessons_course on public.course_lessons(course_id);
create index if not exists idx_course_enrollments_course_user on public.course_enrollments(course_id, user_id);
create index if not exists idx_course_attempts_student on public.course_lesson_attempts(course_id, student_id);
create index if not exists idx_course_attempts_lesson on public.course_lesson_attempts(course_id, lesson_number);
create index if not exists idx_course_responses_student_lesson on public.course_question_responses(course_id, student_id, lesson_number);
create index if not exists idx_course_responses_question on public.course_question_responses(course_id, lesson_number, question_id);
create index if not exists idx_course_responses_review on public.course_question_responses(course_id, needs_teacher_review);
create index if not exists idx_course_question_catalog_question on public.course_question_catalog(course_id, lesson_number, question_id);
create index if not exists idx_course_concepts_course_tag on public.course_concepts(course_id, concept_tag);
create index if not exists idx_course_remediation_resources_tag on public.course_remediation_resources(course_id, concept_tag, level);
create index if not exists idx_course_small_groups_tag on public.course_small_groups(course_id, concept_tag, status);
create index if not exists idx_course_small_group_members_student on public.course_small_group_members(student_id);
