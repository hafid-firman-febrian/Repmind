create type public.fitness_goal as enum ('lose_weight', 'build_muscle', 'stay_fit');
create type public.fitness_level as enum ('beginner', 'intermediate', 'advanced');
create type public.equipment as enum (
  'dumbbell', 'barbell', 'kettlebell', 'resistance_band', 'pull_up_bar', 'bench', 'machine'
);

create table public.profiles (
  id             uuid primary key references auth.users (id) on delete cascade,
  display_name   text,
  avatar_url     text,
  goal           public.fitness_goal,
  level          public.fitness_level,
  equipment      public.equipment[] not null default '{}',
  days_per_week  smallint check (days_per_week between 2 and 6),
  weight_kg      numeric(5, 1) check (weight_kg between 25 and 350),
  height_cm      numeric(5, 1) check (height_cm between 100 and 250),
  onboarded_at   timestamptz,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "Users can view their own profile"
  on public.profiles for select to authenticated
  using ((select auth.uid()) = id);

create policy "Users can update their own profile"
  on public.profiles for update to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

create function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name, avatar_url)
  values (
    new.id,
    coalesce(
      nullif(new.raw_user_meta_data ->> 'full_name', ''),
      nullif(new.raw_user_meta_data ->> 'name', ''),
      split_part(new.email, '@', 1)
    ),
    coalesce(
      new.raw_user_meta_data ->> 'avatar_url',
      new.raw_user_meta_data ->> 'picture'
    )
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

create function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();
