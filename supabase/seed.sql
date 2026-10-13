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
