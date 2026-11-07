begin;
create extension if not exists pgtap with schema extensions;
select plan(8);

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'alice@test.dev'),
  ('22222222-2222-2222-2222-222222222222', 'bob@test.dev');

insert into public.workout_plans (id, user_id, version, title, goal, level, days_per_week, ai_model, archived_at) values
  ('aaaaaaaa-0000-4000-8000-000000000001', '11111111-1111-1111-1111-111111111111', 1, 'Alice Plan One', 'build_muscle', 'beginner', 3, 'gemini_flash', now()),
  ('aaaaaaaa-0000-4000-8000-000000000002', '11111111-1111-1111-1111-111111111111', 2, 'Alice Plan Two', 'build_muscle', 'beginner', 3, 'gemini_flash', null),
  ('bbbbbbbb-0000-4000-8000-000000000001', '22222222-2222-2222-2222-222222222222', 1, 'Bob Plan One', 'build_muscle', 'beginner', 3, 'gemini_flash', null);

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);

select lives_ok(
  $$ insert into public.coach_tips (user_id, plan_id, tip_date, content)
     values ('11111111-1111-1111-1111-111111111111', 'aaaaaaaa-0000-4000-8000-000000000001', '2026-11-05', 'Keep your shoulders back and your core tight today.') $$,
  'a user can add a tip for their own plan');

select throws_ok(
  $$ insert into public.coach_tips (user_id, plan_id, tip_date, content)
     values ('22222222-2222-2222-2222-222222222222', 'aaaaaaaa-0000-4000-8000-000000000001', '2026-11-06', 'Pretending to be Bob on Alice''s plan.') $$,
  '42501', null,
  'a user cannot add a tip for another user');

select throws_ok(
  $$ insert into public.coach_tips (user_id, plan_id, tip_date, content)
     values ('11111111-1111-1111-1111-111111111111', 'bbbbbbbb-0000-4000-8000-000000000001', '2026-11-06', 'Writing a tip against the plan of Bob.') $$,
  '42501', null,
  'a user cannot add a tip for a plan owned by another user');

select throws_ok(
  $$ insert into public.coach_tips (user_id, plan_id, tip_date, content)
     values ('11111111-1111-1111-1111-111111111111', 'aaaaaaaa-0000-4000-8000-000000000001', '2026-11-05', 'A second tip for the same day and plan.') $$,
  '23505', null,
  'a user gets one tip per day and plan');

select lives_ok(
  $$ insert into public.coach_tips (user_id, plan_id, tip_date, content)
     values ('11111111-1111-1111-1111-111111111111', 'aaaaaaaa-0000-4000-8000-000000000002', '2026-11-05', 'Same day but a different plan version.') $$,
  'the same day is allowed for a different plan');

select throws_ok(
  $$ insert into public.coach_tips (user_id, plan_id, tip_date, content)
     values ('11111111-1111-1111-1111-111111111111', 'aaaaaaaa-0000-4000-8000-000000000001', '2026-11-07', repeat('a', 19)) $$,
  '23514', null,
  'a tip cannot be shorter than 20 characters');

select throws_ok(
  $$ insert into public.coach_tips (user_id, plan_id, tip_date, content)
     values ('11111111-1111-1111-1111-111111111111', 'aaaaaaaa-0000-4000-8000-000000000001', '2026-11-07', repeat('a', 161)) $$,
  '23514', null,
  'a tip cannot exceed 160 characters');

select set_config('request.jwt.claims',
  '{"sub": "22222222-2222-2222-2222-222222222222", "role": "authenticated"}', true);

select is(
  (select count(*)::int from public.coach_tips), 0,
  'another user cannot read the tips');

select * from finish();
rollback;
