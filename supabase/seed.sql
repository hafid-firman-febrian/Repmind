insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, recovery_token, email_change_token_new, email_change
) values (
  '00000000-0000-0000-0000-000000000000',
  'd0d0d0d0-0000-4000-8000-000000000001',
  'authenticated',
  'authenticated',
  'demo@repmind.dev',
  extensions.crypt('repmind-demo', extensions.gen_salt('bf')),
  now(),
  '{"provider": "email", "providers": ["email"]}',
  '{"full_name": "Alex"}',
  now(),
  now(),
  '', '', '', ''
);

insert into auth.identities (
  id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at
) values (
  gen_random_uuid(),
  'd0d0d0d0-0000-4000-8000-000000000001',
  'd0d0d0d0-0000-4000-8000-000000000001',
  '{"sub": "d0d0d0d0-0000-4000-8000-000000000001", "email": "demo@repmind.dev", "email_verified": true}',
  'email',
  now(),
  now(),
  now()
);

update public.profiles
set goal = 'build_muscle',
    level = 'intermediate',
    equipment = '{dumbbell,bench}',
    days_per_week = 4,
    weight_kg = 78,
    height_cm = 178,
    onboarded_at = now()
where id = 'd0d0d0d0-0000-4000-8000-000000000001';

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, recovery_token, email_change_token_new, email_change
) values (
  '00000000-0000-0000-0000-000000000000',
  'd0d0d0d0-0000-4000-8000-000000000002',
  'authenticated',
  'authenticated',
  'coach@repmind.dev',
  extensions.crypt('repmind-demo', extensions.gen_salt('bf')),
  now(),
  '{"provider": "email", "providers": ["email"]}',
  '{"full_name": "Alex"}',
  now(),
  now(),
  '', '', '', ''
);

insert into auth.identities (
  id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at
) values (
  gen_random_uuid(),
  'd0d0d0d0-0000-4000-8000-000000000002',
  'd0d0d0d0-0000-4000-8000-000000000002',
  '{"sub": "d0d0d0d0-0000-4000-8000-000000000002", "email": "coach@repmind.dev", "email_verified": true}',
  'email',
  now(),
  now(),
  now()
);

update public.profiles
set goal = 'build_muscle',
    level = 'intermediate',
    equipment = '{dumbbell,bench}',
    days_per_week = 3,
    weight_kg = 78,
    height_cm = 178,
    ai_model = 'gemini_flash_lite',
    onboarded_at = now()
where id = 'd0d0d0d0-0000-4000-8000-000000000002';

insert into public.workout_plans (
  id, user_id, version, title, goal, level, days_per_week, ai_model, instruction, archived_at
) values (
  'd0d0d0d0-0000-4000-8000-000000000101',
  'd0d0d0d0-0000-4000-8000-000000000002',
  1,
  '3-Day Full Body Hypertrophy',
  'build_muscle',
  'intermediate',
  3,
  'gemini_flash_lite',
  null,
  null
);

insert into public.plan_days (id, plan_id, day_number, weekday, title, focus, estimated_minutes) values
  ('d0d0d0d0-0000-4000-8000-000000000201', 'd0d0d0d0-0000-4000-8000-000000000101', 1, 1, 'Full Body A', 'full_body', 60),
  ('d0d0d0d0-0000-4000-8000-000000000202', 'd0d0d0d0-0000-4000-8000-000000000101', 2, 3, 'Full Body B', 'full_body', 60),
  ('d0d0d0d0-0000-4000-8000-000000000203', 'd0d0d0d0-0000-4000-8000-000000000101', 3, 5, 'Full Body C', 'full_body', 60);

insert into public.plan_exercises (id, day_id, position, exercise_id, sets, reps, rest_seconds) values
  ('d0d0d0d0-0000-4000-8000-000000000301', 'd0d0d0d0-0000-4000-8000-000000000201', 1, 'goblet_squat', 4, '8-10', 90),
  ('d0d0d0d0-0000-4000-8000-000000000302', 'd0d0d0d0-0000-4000-8000-000000000201', 2, 'dumbbell_bench_press', 4, '8-10', 90),
  ('d0d0d0d0-0000-4000-8000-000000000303', 'd0d0d0d0-0000-4000-8000-000000000201', 3, 'chest_supported_dumbbell_row', 4, '10-12', 60),
  ('d0d0d0d0-0000-4000-8000-000000000304', 'd0d0d0d0-0000-4000-8000-000000000201', 4, 'dumbbell_lateral_raise', 3, '12-15', 60),
  ('d0d0d0d0-0000-4000-8000-000000000305', 'd0d0d0d0-0000-4000-8000-000000000201', 5, 'dead_bug', 3, '30s', 45),
  ('d0d0d0d0-0000-4000-8000-000000000311', 'd0d0d0d0-0000-4000-8000-000000000202', 1, 'dumbbell_romanian_deadlift', 4, '8-10', 90),
  ('d0d0d0d0-0000-4000-8000-000000000312', 'd0d0d0d0-0000-4000-8000-000000000202', 2, 'incline_dumbbell_press', 4, '8-10', 90),
  ('d0d0d0d0-0000-4000-8000-000000000313', 'd0d0d0d0-0000-4000-8000-000000000202', 3, 'dumbbell_row', 4, '10-12', 60),
  ('d0d0d0d0-0000-4000-8000-000000000314', 'd0d0d0d0-0000-4000-8000-000000000202', 4, 'dumbbell_shoulder_press', 3, '10-12', 60),
  ('d0d0d0d0-0000-4000-8000-000000000315', 'd0d0d0d0-0000-4000-8000-000000000202', 5, 'plank', 3, '45s', 45),
  ('d0d0d0d0-0000-4000-8000-000000000321', 'd0d0d0d0-0000-4000-8000-000000000203', 1, 'dumbbell_bulgarian_split_squat', 3, '10-12', 90),
  ('d0d0d0d0-0000-4000-8000-000000000322', 'd0d0d0d0-0000-4000-8000-000000000203', 2, 'dumbbell_floor_press', 4, '8-10', 90),
  ('d0d0d0d0-0000-4000-8000-000000000323', 'd0d0d0d0-0000-4000-8000-000000000203', 3, 'renegade_row', 3, '10', 60),
  ('d0d0d0d0-0000-4000-8000-000000000324', 'd0d0d0d0-0000-4000-8000-000000000203', 4, 'dumbbell_bicep_curl', 3, '12', 60),
  ('d0d0d0d0-0000-4000-8000-000000000325', 'd0d0d0d0-0000-4000-8000-000000000203', 5, 'dumbbell_overhead_triceps_extension', 3, '12', 60);
