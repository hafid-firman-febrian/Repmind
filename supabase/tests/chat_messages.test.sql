begin;
create extension if not exists pgtap with schema extensions;
select plan(10);

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'alice@test.dev'),
  ('22222222-2222-2222-2222-222222222222', 'bob@test.dev');

set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}', true);

select lives_ok(
  $$ insert into public.chat_messages (user_id, role, content)
     values ('11111111-1111-1111-1111-111111111111', 'user', 'How heavy should I go?') $$,
  'a user can add a message to their own history');

select throws_ok(
  $$ insert into public.chat_messages (user_id, role, content)
     values ('22222222-2222-2222-2222-222222222222', 'user', 'Pretending to be Bob') $$,
  '42501', null,
  'a user cannot add a message to another user''s history');

select throws_ok(
  $$ insert into public.chat_messages (user_id, role, content, proposal)
     values ('11111111-1111-1111-1111-111111111111', 'user', 'Sneaky', '{"summary": "x"}') $$,
  '23514', null,
  'only assistant messages can carry a proposal');

select throws_ok(
  $$ insert into public.chat_messages (user_id, role, content)
     values ('11111111-1111-1111-1111-111111111111', 'user', '') $$,
  '23514', null,
  'a message cannot be empty');

select throws_ok(
  $$ insert into public.chat_messages (user_id, role, content)
     values ('11111111-1111-1111-1111-111111111111', 'user', repeat('a', 8001)) $$,
  '23514', null,
  'a message cannot exceed 8000 characters');

select is_empty(
  $$ update public.chat_messages set content = 'Edited' returning id $$,
  'a user cannot update messages');

select is_empty(
  $$ delete from public.chat_messages returning id $$,
  'a user cannot delete messages');

select is(
  (select content from public.chat_messages), 'How heavy should I go?',
  'the message is unchanged after the update and delete attempts');

select set_config('request.jwt.claims',
  '{"sub": "22222222-2222-2222-2222-222222222222", "role": "authenticated"}', true);

select is(
  (select count(*)::int from public.chat_messages), 0,
  'another user cannot read the messages');

reset role;
set local role anon;
select is_empty(
  'select id from public.chat_messages',
  'anonymous visitors see no messages');

select * from finish();
rollback;
