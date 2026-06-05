-- CAASPP Math Prep Course - Supabase Pilot Schema
-- Run this once in Supabase SQL Editor after creating the project.
-- This schema is designed for the Lesson 1 pilot and expands cleanly to 20 lessons.

create extension if not exists "pgcrypto";

-- Profiles extend Supabase Auth users.
create table if not exists public.profiles (
  id uuid references auth.users on delete cascade primary key,
  email text,
  full_name text not null,
  role text not null default 'student' check (role in ('student', 'teacher', 'staff', 'admin')),
  username text unique,
  contact_email text,
  is_active boolean default true,
  created_by uuid references auth.users(id),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, full_name, role, username, contact_email, is_active, created_by)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
    coalesce(new.raw_user_meta_data->>'role', 'student'),
    new.raw_user_meta_data->>'username',
    new.raw_user_meta_data->>'contact_email',
    true,
    nullif(new.raw_user_meta_data->>'created_by', '')::uuid
  )
  on conflict (id) do nothing;
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Course shell. Store all 20 lesson columns even while only Lesson 1 is active.
create table if not exists public.course_lessons (
  id int primary key,
  module_number int not null,
  lesson_number int not null,
  title text not null,
  status text not null default 'upcoming' check (status in ('active', 'upcoming', 'hidden')),
  total_questions int default 0,
  total_points numeric(6,2) default 0,
  created_at timestamptz default now()
);

insert into public.course_lessons (id, module_number, lesson_number, title, status, total_questions, total_points)
values
  (1, 1, 1, 'Undo the Equation', 'active', 17, 29),
  (2, 1, 2, 'Inequalities Are Ranges', 'upcoming', 0, 0),
  (3, 1, 3, 'Lines Tell Stories', 'upcoming', 0, 0),
  (4, 1, 4, 'Slope, Intercepts, and Meaning', 'upcoming', 0, 0),
  (5, 1, 5, 'Function Notation and Mini Performance Task', 'upcoming', 0, 0),
  (6, 2, 6, 'Module 2 Lesson 6', 'upcoming', 0, 0),
  (7, 2, 7, 'Module 2 Lesson 7', 'upcoming', 0, 0),
  (8, 2, 8, 'Module 2 Lesson 8', 'upcoming', 0, 0),
  (9, 2, 9, 'Module 2 Lesson 9', 'upcoming', 0, 0),
  (10, 2, 10, 'Module 2 Lesson 10', 'upcoming', 0, 0),
  (11, 3, 11, 'Module 3 Lesson 11', 'upcoming', 0, 0),
  (12, 3, 12, 'Module 3 Lesson 12', 'upcoming', 0, 0),
  (13, 3, 13, 'Module 3 Lesson 13', 'upcoming', 0, 0),
  (14, 3, 14, 'Module 3 Lesson 14', 'upcoming', 0, 0),
  (15, 3, 15, 'Module 3 Lesson 15', 'upcoming', 0, 0),
  (16, 4, 16, 'Module 4 Lesson 16', 'upcoming', 0, 0),
  (17, 4, 17, 'Module 4 Lesson 17', 'upcoming', 0, 0),
  (18, 4, 18, 'Module 4 Lesson 18', 'upcoming', 0, 0),
  (19, 4, 19, 'Module 4 Lesson 19', 'upcoming', 0, 0),
  (20, 4, 20, 'Module 4 Lesson 20', 'upcoming', 0, 0)
on conflict (id) do update set
  module_number = excluded.module_number,
  lesson_number = excluded.lesson_number,
  title = excluded.title,
  status = excluded.status,
  total_questions = excluded.total_questions,
  total_points = excluded.total_points;

-- One row per student per lesson.
create table if not exists public.lesson_attempts (
  id uuid default gen_random_uuid() primary key,
  student_id uuid references public.profiles(id) on delete cascade not null,
  lesson_id int references public.course_lessons(id) on delete cascade not null,
  status text default 'not_started' check (status in ('not_started', 'in_progress', 'submitted', 'graded', 'reset')),
  score numeric(6,2) default 0,
  max_score numeric(6,2) default 0,
  percent numeric(5,2) default 0,
  needs_teacher_review boolean default false,
  started_at timestamptz,
  submitted_at timestamptz,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(student_id, lesson_id)
);

-- One row per question. This is what makes class trends and small groups practical.
create table if not exists public.student_question_responses (
  id uuid default gen_random_uuid() primary key,
  student_id uuid references public.profiles(id) on delete cascade not null,
  lesson_id int references public.course_lessons(id) on delete cascade not null,
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
  unique(student_id, lesson_id, question_id)
);

create table if not exists public.teacher_overrides (
  id uuid default gen_random_uuid() primary key,
  response_id uuid references public.student_question_responses(id) on delete cascade not null,
  teacher_id uuid references public.profiles(id) not null,
  original_score numeric(6,2),
  override_score numeric(6,2) not null,
  feedback text,
  created_at timestamptz default now()
);

-- Future use: assign a retry lesson, lower scaffold, alternate video, or challenge path.
create table if not exists public.remediation_assignments (
  id uuid default gen_random_uuid() primary key,
  student_id uuid references public.profiles(id) on delete cascade not null,
  lesson_id int references public.course_lessons(id) on delete cascade not null,
  assigned_by uuid references public.profiles(id),
  concept_tag text not null,
  level text not null default 'scaffolded' check (level in ('scaffolded', 'same_level', 'challenge')),
  status text not null default 'assigned' check (status in ('assigned', 'completed', 'dismissed')),
  created_at timestamptz default now(),
  completed_at timestamptz
);

create or replace function public.update_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists update_profiles_updated_at on public.profiles;
create trigger update_profiles_updated_at
  before update on public.profiles
  for each row execute procedure public.update_updated_at();

drop trigger if exists update_lesson_attempts_updated_at on public.lesson_attempts;
create trigger update_lesson_attempts_updated_at
  before update on public.lesson_attempts
  for each row execute procedure public.update_updated_at();

drop trigger if exists update_question_responses_updated_at on public.student_question_responses;
create trigger update_question_responses_updated_at
  before update on public.student_question_responses
  for each row execute procedure public.update_updated_at();

-- Gradebook view.
create or replace view public.lesson_score_summary as
select
  p.id as student_id,
  p.full_name,
  p.username,
  p.created_by,
  cl.id as lesson_id,
  cl.title as lesson_title,
  cl.status as lesson_status,
  coalesce(la.status, 'not_started') as attempt_status,
  coalesce(la.score, 0) as score,
  coalesce(la.max_score, cl.total_points, 0) as max_score,
  coalesce(la.percent, 0) as percent,
  coalesce(la.needs_teacher_review, false) as needs_teacher_review,
  la.updated_at as last_activity
from public.profiles p
cross join public.course_lessons cl
left join public.lesson_attempts la
  on la.student_id = p.id and la.lesson_id = cl.id
where p.role = 'student';

-- Class trend view. This powers "students need review on..." and small groups.
create or replace view public.class_question_trends as
select
  lesson_id,
  question_id,
  max(prompt) as prompt,
  max(section_title) as section_title,
  count(*) as attempts,
  count(*) filter (where score < max_score) as needs_support,
  round(avg(case when max_score > 0 then score / max_score else 0 end) * 100, 1) as average_percent
from public.student_question_responses
group by lesson_id, question_id;

alter table public.profiles enable row level security;
alter table public.course_lessons enable row level security;
alter table public.lesson_attempts enable row level security;
alter table public.student_question_responses enable row level security;
alter table public.teacher_overrides enable row level security;
alter table public.remediation_assignments enable row level security;

create or replace function public.get_my_role()
returns text as $$
  select role from public.profiles where id = auth.uid();
$$ language sql security definer stable;

create policy "Anyone signed in can read course lessons"
  on public.course_lessons for select
  using (auth.uid() is not null);

create policy "Users can read own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Admin staff read all profiles"
  on public.profiles for select
  using (public.get_my_role() in ('admin', 'staff'));

create policy "Teachers read own students"
  on public.profiles for select
  using (public.get_my_role() = 'teacher' and (created_by = auth.uid() or id = auth.uid()));

create policy "Admin staff update profiles"
  on public.profiles for update
  using (public.get_my_role() in ('admin', 'staff'));

create policy "Students manage own attempts"
  on public.lesson_attempts for all
  using (auth.uid() = student_id)
  with check (auth.uid() = student_id);

create policy "Teachers read own student attempts"
  on public.lesson_attempts for select
  using (
    public.get_my_role() in ('teacher', 'admin', 'staff')
    and exists (
      select 1 from public.profiles
      where profiles.id = lesson_attempts.student_id
      and (profiles.created_by = auth.uid() or public.get_my_role() in ('admin', 'staff'))
    )
  );

create policy "Teachers update own student attempts"
  on public.lesson_attempts for update
  using (
    public.get_my_role() in ('teacher', 'admin', 'staff')
    and exists (
      select 1 from public.profiles
      where profiles.id = lesson_attempts.student_id
      and (profiles.created_by = auth.uid() or public.get_my_role() in ('admin', 'staff'))
    )
  );

create policy "Students manage own question responses"
  on public.student_question_responses for all
  using (auth.uid() = student_id)
  with check (auth.uid() = student_id);

create policy "Teachers read own student question responses"
  on public.student_question_responses for select
  using (
    public.get_my_role() in ('teacher', 'admin', 'staff')
    and exists (
      select 1 from public.profiles
      where profiles.id = student_question_responses.student_id
      and (profiles.created_by = auth.uid() or public.get_my_role() in ('admin', 'staff'))
    )
  );

create policy "Teachers update own student question responses"
  on public.student_question_responses for update
  using (
    public.get_my_role() in ('teacher', 'admin', 'staff')
    and exists (
      select 1 from public.profiles
      where profiles.id = student_question_responses.student_id
      and (profiles.created_by = auth.uid() or public.get_my_role() in ('admin', 'staff'))
    )
  );

create policy "Teachers manage overrides"
  on public.teacher_overrides for all
  using (public.get_my_role() in ('teacher', 'admin', 'staff'))
  with check (public.get_my_role() in ('teacher', 'admin', 'staff'));

create policy "Teachers manage remediation"
  on public.remediation_assignments for all
  using (public.get_my_role() in ('teacher', 'admin', 'staff') or auth.uid() = student_id)
  with check (public.get_my_role() in ('teacher', 'admin', 'staff'));

create index if not exists idx_profiles_role on public.profiles(role);
create index if not exists idx_profiles_created_by on public.profiles(created_by);
create index if not exists idx_lesson_attempts_student on public.lesson_attempts(student_id);
create index if not exists idx_lesson_attempts_lesson on public.lesson_attempts(lesson_id);
create index if not exists idx_question_responses_student_lesson on public.student_question_responses(student_id, lesson_id);
create index if not exists idx_question_responses_question on public.student_question_responses(lesson_id, question_id);
create index if not exists idx_question_responses_review on public.student_question_responses(needs_teacher_review);
