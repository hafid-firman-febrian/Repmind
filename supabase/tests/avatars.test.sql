begin;
create extension if not exists pgtap with schema extensions;
select plan(3);

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'alice@test.dev');

select is(
  (select public from storage.buckets where id = 'avatars'),
  true,
  'the avatars bucket exists and is public');

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);

select lives_ok(
  $$ insert into storage.objects (bucket_id, name)
     values ('avatars', '11111111-1111-1111-1111-111111111111/avatar.jpg') $$,
  'a user can upload into their own avatar folder');

select throws_ok(
  $$ insert into storage.objects (bucket_id, name)
     values ('avatars', '22222222-2222-2222-2222-222222222222/avatar.jpg') $$,
  '42501', null,
  'a user cannot upload into another user''s folder');

select * from finish();
rollback;
