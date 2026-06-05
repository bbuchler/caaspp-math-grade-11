-- CAASPP / Altus Courses class-section architecture.
-- Paste this after the shared course schema is already installed.
-- This is additive: it does not change existing Driver's Ed, CAASPP, or auth data.

create table if not exists public.course_class_sections (
  id uuid default gen_random_uuid() primary key,
  course_id text references public.courses(id) on delete cascade not null,
  name text not null,
  location text,
  term text,
  status text not null default 'active' check (status in ('active', 'archived')),
  created_by uuid references public.profiles(id),
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique(course_id, name, term)
);

create table if not exists public.course_class_teachers (
  id uuid default gen_random_uuid() primary key,
  class_id uuid references public.course_class_sections(id) on delete cascade not null,
  teacher_id uuid references public.profiles(id) on delete cascade not null,
  role text not null default 'teacher' check (role in ('teacher', 'co_teacher', 'admin')),
  status text not null default 'active' check (status in ('active', 'inactive')),
  created_by uuid references public.profiles(id),
  created_at timestamptz default now(),
  unique(class_id, teacher_id)
);

create table if not exists public.course_class_students (
  id uuid default gen_random_uuid() primary key,
  class_id uuid references public.course_class_sections(id) on delete cascade not null,
  student_id uuid references public.profiles(id) on delete cascade not null,
  status text not null default 'active' check (status in ('active', 'inactive', 'completed')),
  created_by uuid references public.profiles(id),
  created_at timestamptz default now(),
  unique(class_id, student_id)
);

create or replace view public.course_class_teacher_directory
with (security_invoker = true) as
select
  ccs.course_id,
  ccs.id as class_id,
  ccs.name as class_name,
  ccs.location,
  cct.teacher_id,
  p.full_name,
  p.username,
  p.email,
  cct.role,
  cct.status
from public.course_class_teachers cct
join public.course_class_sections ccs on ccs.id = cct.class_id
join public.profiles p on p.id = cct.teacher_id;

create or replace view public.course_class_student_directory
with (security_invoker = true) as
select
  ccs.course_id,
  ccs.id as class_id,
  ccs.name as class_name,
  ccs.location,
  ccst.student_id,
  p.full_name,
  p.username,
  p.email,
  ccst.status
from public.course_class_students ccst
join public.course_class_sections ccs on ccs.id = ccst.class_id
join public.profiles p on p.id = ccst.student_id;

alter table public.course_class_sections enable row level security;
alter table public.course_class_teachers enable row level security;
alter table public.course_class_students enable row level security;

create or replace function public.altus_courses_can_view_class(target_class_id uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select
    public.altus_courses_get_my_role() in ('staff', 'admin')
    or exists (
      select 1
      from public.course_class_teachers cct
      where cct.class_id = target_class_id
        and cct.teacher_id = auth.uid()
        and cct.status = 'active'
    );
$$;

drop policy if exists "Admins manage class sections" on public.course_class_sections;
drop policy if exists "Teachers read assigned class sections" on public.course_class_sections;
drop policy if exists "Admins manage class teachers" on public.course_class_teachers;
drop policy if exists "Teachers read assigned class teachers" on public.course_class_teachers;
drop policy if exists "Admins and class teachers manage class students" on public.course_class_students;
drop policy if exists "Teachers read assigned class students" on public.course_class_students;

create policy "Admins manage class sections"
  on public.course_class_sections for all
  using (public.altus_courses_get_my_role() in ('staff', 'admin'))
  with check (public.altus_courses_get_my_role() in ('staff', 'admin'));

create policy "Teachers read assigned class sections"
  on public.course_class_sections for select
  using (public.altus_courses_can_view_class(id));

create policy "Admins manage class teachers"
  on public.course_class_teachers for all
  using (public.altus_courses_get_my_role() in ('staff', 'admin'))
  with check (public.altus_courses_get_my_role() in ('staff', 'admin'));

create policy "Teachers read assigned class teachers"
  on public.course_class_teachers for select
  using (public.altus_courses_can_view_class(class_id));

create policy "Admins and class teachers manage class students"
  on public.course_class_students for all
  using (public.altus_courses_can_view_class(class_id))
  with check (public.altus_courses_can_view_class(class_id));

create policy "Teachers read assigned class students"
  on public.course_class_students for select
  using (public.altus_courses_can_view_class(class_id));

create index if not exists idx_course_class_sections_course on public.course_class_sections(course_id, status);
create index if not exists idx_course_class_teachers_class on public.course_class_teachers(class_id, status);
create index if not exists idx_course_class_teachers_teacher on public.course_class_teachers(teacher_id, status);
create index if not exists idx_course_class_students_class on public.course_class_students(class_id, status);
create index if not exists idx_course_class_students_student on public.course_class_students(student_id, status);
