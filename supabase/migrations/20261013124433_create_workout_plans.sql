create table public.workout_plans (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references auth.users (id) on delete cascade,
  version        integer not null check (version > 0),
  title          text not null check (char_length(title) between 3 and 60),
  goal           public.fitness_goal not null,
  level          public.fitness_level not null,
  days_per_week  smallint not null check (days_per_week between 2 and 6),
  ai_model       public.ai_model not null,
  instruction    text check (char_length(instruction) between 3 and 200),
  archived_at    timestamptz,
  created_at     timestamptz not null default now(),
  unique (user_id, version)
);

create unique index workout_plans_one_active_per_user
  on public.workout_plans (user_id) where archived_at is null;

create table public.plan_days (
  id                 uuid primary key default gen_random_uuid(),
  plan_id            uuid not null references public.workout_plans (id) on delete cascade,
  day_number         smallint not null check (day_number between 1 and 6),
  weekday            smallint not null check (weekday between 1 and 7),
  title              text not null check (char_length(title) between 3 and 40),
  focus              public.workout_focus not null,
  estimated_minutes  smallint not null check (estimated_minutes between 15 and 120),
  unique (plan_id, day_number),
  unique (plan_id, weekday)
);

create table public.plan_exercises (
  id            uuid primary key default gen_random_uuid(),
  day_id        uuid not null references public.plan_days (id) on delete cascade,
  position      smallint not null check (position between 1 and 8),
  exercise_id   text not null references public.exercises (id),
  sets          smallint not null check (sets between 1 and 8),
  reps          text not null check (reps ~ '^[0-9]{1,3}(-[0-9]{1,3})?s?$'),
  rest_seconds  smallint not null check (rest_seconds between 15 and 300),
  unique (day_id, position),
  unique (day_id, exercise_id)
);

alter table public.workout_plans enable row level security;
alter table public.plan_days enable row level security;
alter table public.plan_exercises enable row level security;

create policy "Users can view their own plans"
  on public.workout_plans for select to authenticated
  using ((select auth.uid()) = user_id);

create policy "Users can view the days of their own plans"
  on public.plan_days for select to authenticated
  using (exists (
    select 1 from public.workout_plans p
    where p.id = plan_id and p.user_id = (select auth.uid())
  ));

create policy "Users can view the exercises of their own plans"
  on public.plan_exercises for select to authenticated
  using (exists (
    select 1 from public.plan_days d
    join public.workout_plans p on p.id = d.plan_id
    where d.id = day_id and p.user_id = (select auth.uid())
  ));

create function public.save_generated_plan(p_plan jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_profile public.profiles%rowtype;
  v_plan_id uuid;
  v_day jsonb;
  v_day_id uuid;
begin
  if v_user_id is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;

  select * into v_profile from public.profiles where id = v_user_id;
  if not found or v_profile.onboarded_at is null then
    raise exception 'profile is not onboarded' using errcode = '55000';
  end if;

  if jsonb_array_length(p_plan -> 'days') is distinct from v_profile.days_per_week::integer then
    raise exception 'plan must have % days', v_profile.days_per_week using errcode = '22023';
  end if;

  update public.workout_plans
  set archived_at = now()
  where user_id = v_user_id and archived_at is null;

  insert into public.workout_plans (
    user_id, version, title, goal, level, days_per_week, ai_model, instruction
  )
  values (
    v_user_id,
    (select coalesce(max(version), 0) + 1 from public.workout_plans where user_id = v_user_id),
    p_plan ->> 'title',
    v_profile.goal,
    v_profile.level,
    v_profile.days_per_week,
    (p_plan ->> 'ai_model')::public.ai_model,
    p_plan ->> 'instruction'
  )
  returning id into v_plan_id;

  for v_day in select value from jsonb_array_elements(p_plan -> 'days') loop
    insert into public.plan_days (plan_id, day_number, weekday, title, focus, estimated_minutes)
    values (
      v_plan_id,
      (v_day ->> 'day_number')::smallint,
      (v_day ->> 'weekday')::smallint,
      v_day ->> 'title',
      (v_day ->> 'focus')::public.workout_focus,
      (v_day ->> 'estimated_minutes')::smallint
    )
    returning id into v_day_id;

    insert into public.plan_exercises (day_id, position, exercise_id, sets, reps, rest_seconds)
    select
      v_day_id,
      (exercise ->> 'position')::smallint,
      exercise ->> 'exercise_id',
      (exercise ->> 'sets')::smallint,
      exercise ->> 'reps',
      (exercise ->> 'rest_seconds')::smallint
    from jsonb_array_elements(v_day -> 'exercises') as exercise;
  end loop;

  return v_plan_id;
end;
$$;

revoke execute on function public.save_generated_plan(jsonb) from public, anon;
grant execute on function public.save_generated_plan(jsonb) to authenticated;
