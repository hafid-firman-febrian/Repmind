begin;
create extension if not exists pgtap with schema extensions;
select plan(8);

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'alice@test.dev');

insert into storage.objects (bucket_id, name)
values ('avatars', '22222222-2222-2222-2222-222222222222/avatar.jpg');

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

select is_empty(
  $$ select id from storage.objects
     where name = '22222222-2222-2222-2222-222222222222/avatar.jpg' $$,
  'a user cannot read another user''s avatar');

select is_empty(
  $$ update storage.objects set metadata = '{}'::jsonb
     where name = '22222222-2222-2222-2222-222222222222/avatar.jpg'
     returning id $$,
  'a user cannot update another user''s avatar');

select throws_ok(
  $$ update storage.objects
     set name = '22222222-2222-2222-2222-222222222222/stolen.jpg'
     where name = '11111111-1111-1111-1111-111111111111/avatar.jpg' $$,
  '42501', null,
  'a user cannot move their avatar into another user''s folder');

select set_config('storage.allow_delete_query', 'true', true);

select is_empty(
  $$ delete from storage.objects
     where name = '22222222-2222-2222-2222-222222222222/avatar.jpg'
     returning id $$,
  'a user cannot delete another user''s avatar');

select isnt_empty(
  $$ delete from storage.objects
     where name = '11111111-1111-1111-1111-111111111111/avatar.jpg'
     returning id $$,
  'a user can delete their own avatar');

select * from finish();
rollback;
