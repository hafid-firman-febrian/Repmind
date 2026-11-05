create table public.coach_tips (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users (id) on delete cascade,
  plan_id     uuid not null references public.workout_plans (id) on delete cascade,
  tip_date    date not null,
  content     text not null check (char_length(content) between 20 and 160),
  created_at  timestamptz not null default now(),
  unique (user_id, tip_date, plan_id)
);

alter table public.coach_tips enable row level security;

create policy "Users can view their own coach tips"
  on public.coach_tips for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "Users can add tips for their own plans"
  on public.coach_tips for insert to authenticated
  with check (
    (select auth.uid()) = user_id
    and exists (
      select 1 from public.workout_plans p
      where p.id = plan_id and p.user_id = (select auth.uid())
    )
  );
