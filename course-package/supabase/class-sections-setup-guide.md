# Class Sections Setup Guide

Use this after the main CAASPP/Altus course schema is working.

## What This Adds

This adds the missing class architecture:

- **Class sections**: one course can have multiple classrooms, locations, or periods.
- **Teacher memberships**: one class can have a teacher and co-teachers.
- **Student memberships**: students belong to a class section.
- **Filtered dashboards**: teachers can filter by student, class, and teacher once memberships exist.

## Step 1: Install The Class-Section Tables

In Supabase SQL Editor, paste and run:

```sql
-- Use the full contents of:
-- course-package/supabase/course-class-sections-migration.sql
```

## Step 2: Create A Class Section

Replace the values in angle brackets.

```sql
insert into public.course_class_sections (
  course_id,
  name,
  location,
  term,
  status,
  created_by
)
values (
  'caaspp-math-11',
  '<Class name, such as Period 1 CAASPP Math>',
  '<Location, such as Mesa or Online>',
  '<Term, such as Spring 2026>',
  'active',
  '<your admin user uuid>'
)
returning id;
```

Copy the returned `id`. That is the `class_id`.

## Step 3: Add Teachers To The Class

```sql
insert into public.course_class_teachers (
  class_id,
  teacher_id,
  role,
  status,
  created_by
)
values (
  '<class_id from Step 2>',
  '<teacher profile/user uuid>',
  'teacher',
  'active',
  '<your admin user uuid>'
)
on conflict (class_id, teacher_id) do update set
  role = excluded.role,
  status = 'active';
```

For a co-teacher, use `role = 'co_teacher'`.

## Step 4: Add Students To The Class

```sql
insert into public.course_class_students (
  class_id,
  student_id,
  status,
  created_by
)
values (
  '<class_id from Step 2>',
  '<student profile/user uuid>',
  'active',
  '<your admin user uuid>'
)
on conflict (class_id, student_id) do update set
  status = 'active';
```

## Step 5: Use The Dashboard Filters

After the SQL is installed and memberships exist:

- **Search students** filters by name or username.
- **Class section** filters to one class.
- **Teacher** filters to the classes assigned to that teacher.
- Admins can use all filters.
- Teachers should only see sections they are assigned to.

## Important

The GitHub Pages version can read Supabase data, but it cannot run secure account creation, password resets, AI grading, or Study Buddy APIs. For live teacher/student account creation from the dashboard, deploy this repo to Vercel and set:

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `GEMINI_API_KEY`
- optional: `GEMINI_MODEL`

