-- CAASPP / Altus Courses admin role helper
--
-- Use this AFTER the admin user has been created in Supabase:
-- Authentication > Users > Add user
--
-- Do not create Supabase Auth users with raw SQL for production/pilot courses.
-- Supabase Auth expects internal identity/session fields that are easy to miss.
-- This file only promotes an existing auth user to course admin and enrolls them.

update public.profiles
set
  full_name = 'YOUR NAME',
  role = 'admin',
  username = null,
  is_active = true
where email = 'YOUR_EMAIL_HERE';

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
  'admin',
  'active',
  id
from public.profiles
where email = 'YOUR_EMAIL_HERE'
on conflict (course_id, user_id) do update
set
  role = 'admin',
  status = 'active';
