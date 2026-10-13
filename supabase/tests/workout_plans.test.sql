begin;
create extension if not exists pgtap with schema extensions;
select plan(19);

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'alice@test.dev'),
  ('22222222-2222-2222-2222-222222222222', 'bob@test.dev'),
  ('33333333-3333-3333-3333-333333333333', 'carol@test.dev');

update public.profiles
set goal = 'build_muscle', level = 'beginner', days_per_week = 2,
    weight_kg = 70, height_cm = 175, onboarded_at = now()
where id in ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222');

select set_config('test.plan', $json${
  "title": "Test Plan",
  "ai_model": "gemini_flash",
  "instruction": null,
  "days": [
    {"day_number": 1, "weekday": 1, "title": "Upper Body", "focus": "upper", "estimated_minutes": 30,
     "exercises": [{"position": 1, "exercise_id": "push_up", "sets": 3, "reps": "10", "rest_seconds": 60}]},
    {"day_number": 2, "weekday": 4, "title": "Lower Body", "focus": "lower", "estimated_minutes": 30,
     "exercises": [{"position": 1, "exercise_id": "bodyweight_squat", "sets": 3, "reps": "8-12", "rest_seconds": 60}]}
  ]
}$json$, true);

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);

select lives_ok(
  $$ select public.save_generated_plan(current_setting('test.plan')::jsonb) $$,
  'a user can save a generated plan');

select results_eq(
  'select version, archived_at is null from public.workout_plans order by version',
  $$ values (1, true) $$,
  'the first plan is version 1 and active');

select results_eq(
  'select goal::text, level::text, days_per_week::int, ai_model::text from public.workout_plans',
  $$ values ('build_muscle', 'beginner', 2, 'gemini_flash') $$,
  'the plan snapshots the profile and records the model');

select is(
  (select count(*)::int from public.plan_days), 2,
  'the plan has one row per training day');

select is(
  (select count(*)::int from public.plan_exercises), 2,
  'the exercises are saved with their days');

select lives_ok(
  $$ select public.save_generated_plan(
       jsonb_set(current_setting('test.plan')::jsonb, '{instruction}', '"More core work"')) $$,
  'a user can save an adjusted plan');

select results_eq(
  'select version, archived_at is null, instruction from public.workout_plans order by version',
  $$ values (1, false, null::text), (2, true, 'More core work') $$,
  'adjusting archives the previous version and keeps one active plan');

select throws_ok(
  $$ select public.save_generated_plan(
       jsonb_set(current_setting('test.plan')::jsonb, '{days}',
                 (current_setting('test.plan')::jsonb -> 'days') - 1)) $$,
  '22023', null,
  'a plan with the wrong number of days is rejected');

select throws_ok(
  $$ select public.save_generated_plan(
       jsonb_set(current_setting('test.plan')::jsonb,
                 '{days,0,exercises,0,exercise_id}', '"made_up_move"')) $$,
  '23503', null,
  'a plan with an unknown exercise is rejected');

select is(
  (select count(*)::int from public.workout_plans), 2,
  'rejected plans leave the saved versions untouched');

select throws_ok(
  $$ insert into public.workout_plans (user_id, version, title, goal, level, days_per_week, ai_model)
     values ('11111111-1111-1111-1111-111111111111', 9, 'Sneaky', 'stay_fit', 'beginner', 2, 'gemini_flash') $$,
  '42501', null,
  'a user cannot insert plans directly');

select is_empty(
  $$ update public.workout_plans set title = 'Renamed' returning id $$,
  'a user cannot update plans directly');

select throws_ok(
  $$ insert into public.plan_days (plan_id, day_number, weekday, title, focus, estimated_minutes)
     select id, 3, 7, 'Extra Day', 'core', 20 from public.workout_plans where archived_at is null $$,
  '42501', null,
  'a user cannot add days directly');

select is_empty(
  $$ delete from public.plan_exercises returning id $$,
  'a user cannot delete plan exercises directly');

select set_config('request.jwt.claims',
  '{"sub": "22222222-2222-2222-2222-222222222222", "role": "authenticated"}', true);

select is_empty('select id from public.workout_plans', 'another user cannot see the plans');
select is_empty('select id from public.plan_days', 'another user cannot see the plan days');
select is_empty('select id from public.plan_exercises', 'another user cannot see the plan exercises');

select set_config('request.jwt.claims',
  '{"sub": "33333333-3333-3333-3333-333333333333", "role": "authenticated"}', true);

select throws_ok(
  $$ select public.save_generated_plan(current_setting('test.plan')::jsonb) $$,
  '55000', null,
  'a user who has not finished onboarding cannot save a plan');

reset role;
set local role anon;
select throws_ok(
  $$ select public.save_generated_plan(current_setting('test.plan')::jsonb) $$,
  '42501', null,
  'anonymous visitors cannot call save_generated_plan');

select * from finish();
rollback;
