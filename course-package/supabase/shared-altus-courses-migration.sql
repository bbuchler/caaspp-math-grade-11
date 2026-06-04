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

insert into public.course_lessons (course_id, lesson_number, module_number, title, status, total_questions, total_points)
values
  ('caaspp-math-11', 1, 1, 'Undo the Equation', 'active', 11, 15),
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

create or replace function public.update_course_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists update_courses_updated_at on public.courses;
create trigger update_courses_updated_at
  before update on public.courses
  for each row execute procedure public.update_course_updated_at();

drop trigger if exists update_course_lessons_updated_at on public.course_lessons;
create trigger update_course_lessons_updated_at
  before update on public.course_lessons
  for each row execute procedure public.update_course_updated_at();

drop trigger if exists update_course_enrollments_updated_at on public.course_enrollments;
create trigger update_course_enrollments_updated_at
  before update on public.course_enrollments
  for each row execute procedure public.update_course_updated_at();

drop trigger if exists update_course_lesson_attempts_updated_at on public.course_lesson_attempts;
create trigger update_course_lesson_attempts_updated_at
  before update on public.course_lesson_attempts
  for each row execute procedure public.update_course_updated_at();

drop trigger if exists update_course_question_responses_updated_at on public.course_question_responses;
create trigger update_course_question_responses_updated_at
  before update on public.course_question_responses
  for each row execute procedure public.update_course_updated_at();

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

alter table public.courses enable row level security;
alter table public.course_lessons enable row level security;
alter table public.course_enrollments enable row level security;
alter table public.course_lesson_attempts enable row level security;
alter table public.course_question_responses enable row level security;
alter table public.course_teacher_overrides enable row level security;
alter table public.course_remediation_assignments enable row level security;

-- Course-specific helper name so we do not overwrite any existing app helper.
create or replace function public.altus_courses_get_my_role()
returns text as $$
  select role from public.profiles where id = auth.uid();
$$ language sql security definer stable;

create policy "Signed in users can read active courses"
  on public.courses for select
  using (auth.uid() is not null);

create policy "Signed in users can read course lessons"
  on public.course_lessons for select
  using (auth.uid() is not null);

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

create index if not exists idx_course_lessons_course on public.course_lessons(course_id);
create index if not exists idx_course_enrollments_course_user on public.course_enrollments(course_id, user_id);
create index if not exists idx_course_attempts_student on public.course_lesson_attempts(course_id, student_id);
create index if not exists idx_course_attempts_lesson on public.course_lesson_attempts(course_id, lesson_number);
create index if not exists idx_course_responses_student_lesson on public.course_question_responses(course_id, student_id, lesson_number);
create index if not exists idx_course_responses_question on public.course_question_responses(course_id, lesson_number, question_id);
create index if not exists idx_course_responses_review on public.course_question_responses(course_id, needs_teacher_review);
