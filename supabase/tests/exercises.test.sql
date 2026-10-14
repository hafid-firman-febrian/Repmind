begin;
create extension if not exists pgtap with schema extensions;
select plan(8);

select cmp_ok(
  (select count(*)::int from public.exercises), '>=', 50,
  'the catalog has at least 50 exercises');

select results_eq(
  $$ select focus::text, count(*)::int >= 3 from public.exercises
     where equipment = '{}' group by focus order by focus $$,
  $$ values ('core', true), ('full_body', true), ('lower', true), ('upper', true) $$,
  'every focus has at least three bodyweight exercises');

select is_empty(
  $$ select item from unnest(enum_range(null::public.equipment)) as item
     where (select count(*) from public.exercises where item = any(equipment)) < 2 $$,
  'every equipment type is used by at least two exercises');

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);

select isnt_empty(
  'select id from public.exercises',
  'signed-in users can read the catalog');

select throws_ok(
  $$ insert into public.exercises (id, name, focus, primary_muscle)
     values ('sneaky_move', 'Sneaky Move', 'core', 'Core') $$,
  '42501', null,
  'users cannot add exercises');

select is_empty(
  $$ update public.exercises set name = 'Renamed' returning id $$,
  'users cannot rename exercises');

select is_empty(
  $$ delete from public.exercises returning id $$,
  'users cannot delete exercises');

reset role;
set local role anon;
select is_empty(
  'select id from public.exercises',
  'anonymous visitors cannot read the catalog');

select * from finish();
rollback;
