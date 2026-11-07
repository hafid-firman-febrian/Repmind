begin;
create extension if not exists pgtap with schema extensions;
select plan(28);

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'alice@test.dev'),
  ('22222222-2222-2222-2222-222222222222', 'bob@test.dev'),
  ('33333333-3333-3333-3333-333333333333', 'carol@test.dev');

update public.profiles
set goal = 'build_muscle', level = 'beginner', days_per_week = 2,
    weight_kg = 70, height_cm = 175, equipment = '{dumbbell}', onboarded_at = now()
where id in ('11111111-1111-1111-1111-111111111111',
             '22222222-2222-2222-2222-222222222222',
             '33333333-3333-3333-3333-333333333333');

select set_config('test.plan', $json${
  "title": "Test Plan",
  "ai_model": "gemini_flash",
  "instruction": null,
  "days": [
    {"day_number": 1, "weekday": 1, "title": "Upper Body", "focus": "upper", "estimated_minutes": 35,
     "exercises": [
       {"position": 1, "exercise_id": "push_up", "sets": 3, "reps": "10", "rest_seconds": 60},
       {"position": 2, "exercise_id": "pike_push_up", "sets": 3, "reps": "8-10", "rest_seconds": 75}]},
    {"day_number": 2, "weekday": 4, "title": "Lower Body", "focus": "lower", "estimated_minutes": 40,
     "exercises": [{"position": 1, "exercise_id": "bodyweight_squat", "sets": 3, "reps": "8-12", "rest_seconds": 60}]}
  ]
}$json$, true);

create function public.test_proposal(p_based_on uuid, p_day integer, p_changes jsonb)
returns jsonb
language sql
as $$
  select jsonb_build_object(
    'based_on_plan_id', p_based_on,
    'ai_model', 'gemini_flash_lite',
    'day_number', p_day,
    'summary', 'Coach updated Upper Body',
    'changes', p_changes);
$$;

create function public.test_change(p_from text, p_to text, p_sets integer, p_reps text, p_rest integer)
returns jsonb
language sql
as $$
  select jsonb_build_object(
    'from_exercise_id', p_from, 'to_exercise_id', p_to,
    'sets', p_sets, 'reps', p_reps, 'rest_seconds', p_rest);
$$;

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);

select public.save_generated_plan(current_setting('test.plan')::jsonb);

select set_config('test.v1', (select id::text from public.workout_plans where version = 1), true);

insert into public.chat_messages (id, user_id, role, content, proposal) values
  ('a0000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'assistant', 'Swap it',
   public.test_proposal(current_setting('test.v1')::uuid, 1,
     jsonb_build_array(public.test_change('push_up', 'dumbbell_lateral_raise', 3, '12', 60)))),
  ('a0000000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 'assistant', 'Stale',
   public.test_proposal(current_setting('test.v1')::uuid, 1,
     jsonb_build_array(public.test_change('push_up', 'dumbbell_lateral_raise', 3, '12', 60)))),
  ('b0000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'assistant', 'Unknown exercise',
   public.test_proposal(current_setting('test.v1')::uuid, 1,
     jsonb_build_array(public.test_change('push_up', 'made_up_move', 3, '12', 60)))),
  ('b0000000-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111', 'assistant', 'No equipment',
   public.test_proposal(current_setting('test.v1')::uuid, 1,
     jsonb_build_array(public.test_change('push_up', 'barbell_overhead_press', 3, '12', 60)))),
  ('b0000000-0000-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111', 'assistant', 'Target already in day',
   public.test_proposal(current_setting('test.v1')::uuid, 1,
     jsonb_build_array(public.test_change('push_up', 'pike_push_up', 3, '12', 60)))),
  ('b0000000-0000-0000-0000-000000000004', '11111111-1111-1111-1111-111111111111', 'assistant', 'Nothing changes',
   public.test_proposal(current_setting('test.v1')::uuid, 1,
     jsonb_build_array(public.test_change('push_up', 'push_up', 3, '10', 60)))),
  ('b0000000-0000-0000-0000-000000000005', '11111111-1111-1111-1111-111111111111', 'assistant', 'Same source twice',
   public.test_proposal(current_setting('test.v1')::uuid, 1,
     jsonb_build_array(
       public.test_change('push_up', 'dumbbell_lateral_raise', 3, '12', 60),
       public.test_change('push_up', 'dumbbell_bicep_curl', 3, '12', 60)))),
  ('b0000000-0000-0000-0000-000000000006', '11111111-1111-1111-1111-111111111111', 'assistant', 'Chained swap',
   public.test_proposal(current_setting('test.v1')::uuid, 1,
     jsonb_build_array(
       public.test_change('push_up', 'pike_push_up', 3, '12', 60),
       public.test_change('pike_push_up', 'dumbbell_lateral_raise', 3, '12', 60)))),
  ('b0000000-0000-0000-0000-000000000007', '11111111-1111-1111-1111-111111111111', 'assistant', 'Four changes',
   public.test_proposal(current_setting('test.v1')::uuid, 1,
     jsonb_build_array(
       public.test_change('push_up', 'dumbbell_lateral_raise', 3, '12', 60),
       public.test_change('pike_push_up', 'dumbbell_bicep_curl', 3, '12', 60),
       public.test_change('a', 'b', 3, '12', 60),
       public.test_change('c', 'd', 3, '12', 60)))),
  ('b0000000-0000-0000-0000-000000000008', '11111111-1111-1111-1111-111111111111', 'assistant', 'No changes',
   public.test_proposal(current_setting('test.v1')::uuid, 1, '[]'::jsonb)),
  ('b0000000-0000-0000-0000-000000000009', '11111111-1111-1111-1111-111111111111', 'assistant', 'Source not in day',
   public.test_proposal(current_setting('test.v1')::uuid, 1,
     jsonb_build_array(public.test_change('bodyweight_squat', 'dumbbell_lateral_raise', 3, '12', 60)))),
  ('b0000000-0000-0000-0000-000000000010', '11111111-1111-1111-1111-111111111111', 'assistant', 'Day not in plan',
   public.test_proposal(current_setting('test.v1')::uuid, 5,
     jsonb_build_array(public.test_change('push_up', 'dumbbell_lateral_raise', 3, '12', 60))));

select throws_ok(
  $$ select public.apply_coach_proposal('b0000000-0000-0000-0000-000000000001') $$,
  'RM002', null, 'an exercise missing from the catalog is rejected');

select throws_ok(
  $$ select public.apply_coach_proposal('b0000000-0000-0000-0000-000000000002') $$,
  'RM002', null, 'an exercise outside the user''s equipment is rejected');

select throws_ok(
  $$ select public.apply_coach_proposal('b0000000-0000-0000-0000-000000000003') $$,
  'RM002', null, 'a target exercise already in the day is rejected');

select throws_ok(
  $$ select public.apply_coach_proposal('b0000000-0000-0000-0000-000000000004') $$,
  'RM002', null, 'a proposal that changes nothing is rejected');

select throws_ok(
  $$ select public.apply_coach_proposal('b0000000-0000-0000-0000-000000000005') $$,
  'RM002', null, 'the same source exercise twice is rejected');

select throws_ok(
  $$ select public.apply_coach_proposal('b0000000-0000-0000-0000-000000000006') $$,
  'RM002', null, 'a chained swap is rejected');

select throws_ok(
  $$ select public.apply_coach_proposal('b0000000-0000-0000-0000-000000000007') $$,
  'RM002', null, 'four changes are rejected');

select throws_ok(
  $$ select public.apply_coach_proposal('b0000000-0000-0000-0000-000000000008') $$,
  'RM002', null, 'an empty change list is rejected');

select throws_ok(
  $$ select public.apply_coach_proposal('b0000000-0000-0000-0000-000000000009') $$,
  'RM002', null, 'a source exercise missing from the day is rejected');

select throws_ok(
  $$ select public.apply_coach_proposal('b0000000-0000-0000-0000-000000000010') $$,
  'RM002', null, 'a day missing from the plan is rejected');

select is(
  (select count(*)::int from public.workout_plans), 1,
  'rejected proposals leave the plan untouched');

select lives_ok(
  $$ select public.apply_coach_proposal('a0000000-0000-0000-0000-000000000001') $$,
  'a user can apply a proposal');

select results_eq(
  'select version, archived_at is null from public.workout_plans order by version',
  $$ values (1, false), (2, true) $$,
  'applying archives the old version and activates the new one');

select results_eq(
  $$ select pe.position::int, pe.exercise_id, pe.sets::int, pe.reps, pe.rest_seconds::int
     from public.plan_exercises pe
     join public.plan_days d on d.id = pe.day_id
     join public.workout_plans p on p.id = d.plan_id
     where p.version = 2 and d.day_number = 1
     order by pe.position $$,
  $$ values (1, 'dumbbell_lateral_raise', 3, '12', 60),
            (2, 'pike_push_up', 3, '8-10', 75) $$,
  'the swapped exercise keeps its position and the rest of the day is copied');

select results_eq(
  $$ select d.day_number::int, d.weekday::int, d.title, d.focus::text, d.estimated_minutes::int,
            pe.position::int, pe.exercise_id, pe.sets::int, pe.reps, pe.rest_seconds::int
     from public.plan_exercises pe
     join public.plan_days d on d.id = pe.day_id
     join public.workout_plans p on p.id = d.plan_id
     where p.version = 2 and d.day_number = 2 $$,
  $$ values (2, 4, 'Lower Body', 'lower', 40, 1, 'bodyweight_squat', 3, '8-12', 60) $$,
  'the other day is copied intact');

select results_eq(
  'select title, instruction, ai_model::text from public.workout_plans where version = 2',
  $$ values ('Test Plan', 'Coach updated Upper Body', 'gemini_flash_lite') $$,
  'the new version keeps the title and records the summary and model');

select is(
  (select applied_plan_id from public.chat_messages
   where id = 'a0000000-0000-0000-0000-000000000001'),
  (select id from public.workout_plans where version = 2),
  'the message records the plan it created');

select is(
  public.apply_coach_proposal('a0000000-0000-0000-0000-000000000001'),
  (select id from public.workout_plans where version = 2),
  'applying twice returns the same plan');

select is(
  (select count(*)::int from public.workout_plans), 2,
  'applying twice does not create another version');

select throws_ok(
  $$ select public.apply_coach_proposal('a0000000-0000-0000-0000-000000000002') $$,
  'RM001', null, 'a proposal based on an older version is stale');

select set_config('test.v2', (select id::text from public.workout_plans where version = 2), true);

insert into public.chat_messages (id, user_id, role, content, proposal) values
  ('c0000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'assistant', 'Profile drift',
   public.test_proposal(current_setting('test.v2')::uuid, 1,
     jsonb_build_array(public.test_change('dumbbell_lateral_raise', 'dumbbell_bicep_curl', 3, '12', 60))));

select set_config('request.jwt.claims',
  '{"sub": "22222222-2222-2222-2222-222222222222", "role": "authenticated"}', true);

select throws_ok(
  $$ select public.apply_coach_proposal('a0000000-0000-0000-0000-000000000001') $$,
  'RM002', null, 'another user''s message cannot be applied');

select throws_ok(
  $$ select public.apply_coach_proposal('a0000000-0000-0000-0000-000000000002') $$,
  'RM002', null, 'another user''s pending proposal cannot be applied');

select set_config('request.jwt.claims',
  '{"sub": "33333333-3333-3333-3333-333333333333", "role": "authenticated"}', true);

insert into public.chat_messages (id, user_id, role, content, proposal) values
  ('d0000000-0000-0000-0000-000000000001', '33333333-3333-3333-3333-333333333333', 'assistant', 'No plan',
   public.test_proposal(gen_random_uuid(), 1,
     jsonb_build_array(public.test_change('push_up', 'dumbbell_lateral_raise', 3, '12', 60))));

select throws_ok(
  $$ select public.apply_coach_proposal('d0000000-0000-0000-0000-000000000001') $$,
  'RM001', null, 'a user without an active plan cannot apply a proposal');

reset role;
update public.profiles set days_per_week = 3
where id = '11111111-1111-1111-1111-111111111111';
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);

select throws_ok(
  $$ select public.apply_coach_proposal('c0000000-0000-0000-0000-000000000001') $$,
  'RM003', null, 'a profile that changed after the plan was made is rejected');

select is(
  (select count(*)::int from public.workout_plans where archived_at is null), 1,
  'after every rejection there is still one active plan');

select is(
  (select count(*)::int from public.workout_plans), 2,
  'rejections never create a version');

select is_empty(
  $$ update public.chat_messages set applied_plan_id = null returning id $$,
  'a user cannot reset applied_plan_id directly');

reset role;
set local role anon;
select throws_ok(
  $$ select public.apply_coach_proposal('a0000000-0000-0000-0000-000000000001') $$,
  '42501', null, 'anonymous visitors cannot call apply_coach_proposal');

select * from finish();
rollback;
