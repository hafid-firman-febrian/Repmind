begin;
create extension if not exists pgtap with schema extensions;
select plan(9);

insert into auth.users (id, email, raw_user_meta_data) values
  ('11111111-1111-1111-1111-111111111111', 'alice@test.dev',
   '{"full_name": "Alice Doe", "avatar_url": "https://example.com/alice.png"}'),
  ('22222222-2222-2222-2222-222222222222', 'bob@test.dev', '{}');

select is(
  (select display_name from public.profiles where id = '11111111-1111-1111-1111-111111111111'),
  'Alice Doe',
  'a new user gets a profile named after full_name');

select is(
  (select display_name from public.profiles where id = '22222222-2222-2222-2222-222222222222'),
  'bob',
  'display_name falls back to the email prefix');

select is(
  (select avatar_url from public.profiles where id = '11111111-1111-1111-1111-111111111111'),
  'https://example.com/alice.png',
  'avatar_url is copied from provider metadata');

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);

select results_eq(
  'select id from public.profiles',
  $$ values ('11111111-1111-1111-1111-111111111111'::uuid) $$,
  'a user only sees their own profile');

select isnt_empty(
  $$ update public.profiles set display_name = 'Alice' where id = '11111111-1111-1111-1111-111111111111' returning id $$,
  'a user can update their own profile');

select is_empty(
  $$ update public.profiles set display_name = 'Hacked' where id = '22222222-2222-2222-2222-222222222222' returning id $$,
  'a user cannot update another profile');

select throws_ok(
  $$ insert into public.profiles (id) values ('33333333-3333-3333-3333-333333333333') $$,
  '42501', null,
  'a user cannot insert profiles directly');

select is_empty(
  $$ delete from public.profiles where id = '11111111-1111-1111-1111-111111111111' returning id $$,
  'a user cannot delete profiles directly');

reset role;
set local role anon;
select is_empty('select id from public.profiles', 'anonymous visitors see no profiles');

select * from finish();
rollback;
