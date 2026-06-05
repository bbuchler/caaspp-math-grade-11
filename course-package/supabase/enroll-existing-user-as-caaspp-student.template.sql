-- Use this only as a temporary pilot fallback if the dashboard Add Account
-- API cannot run yet because SUPABASE_SERVICE_ROLE_KEY is missing.
--
-- First create the student in Supabase:
-- Authentication > Users > Add user
--
-- Then replace the email below and run this SQL to enroll that existing
-- auth user in CAASPP Math only.

insert into public.profiles (
  id,
  email,
  full_name,
  role,
  username,
  is_active,
  created_by
)
select
  id,
  email,
  'CAASPP Test Student',
  'student',
  null,
  true,
  id
from auth.users
where email = 'REPLACE_WITH_TEST_STUDENT_EMAIL'
on conflict (id) do update
set
  email = excluded.email,
  full_name = excluded.full_name,
  role = 'student',
  is_active = true;

insert into public.course_enrollments (
  course_id,
  user_id,
  role,
  status,
  created_by
)
select
  'caaspp-math-11',
  id,
  'student',
  'active',
  id
from public.profiles
where email = 'REPLACE_WITH_TEST_STUDENT_EMAIL'
on conflict (course_id, user_id) do update
set
  role = 'student',
  status = 'active';
