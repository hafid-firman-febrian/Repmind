create function public.apply_coach_proposal(p_message_id uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_profile public.profiles%rowtype;
  v_message public.chat_messages%rowtype;
  v_plan public.workout_plans%rowtype;
  v_proposal jsonb;
  v_changes jsonb;
  v_based_on uuid;
  v_day_number smallint;
  v_day_id uuid;
  v_ai_model public.ai_model;
  v_summary text;
  v_check record;
  v_payload jsonb;
  v_new_plan_id uuid;
begin
  if v_user_id is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;

  select * into v_profile from public.profiles where id = v_user_id for update;
  if not found then
    raise exception 'profile not found' using errcode = '55000';
  end if;

  select * into v_message
  from public.chat_messages
  where id = p_message_id
    and user_id = v_user_id
    and role = 'assistant'
    and proposal is not null
  for update;
  if not found then
    raise exception 'proposal not found' using errcode = 'RM002';
  end if;

  if v_message.applied_plan_id is not null then
    return v_message.applied_plan_id;
  end if;

  v_proposal := v_message.proposal;

  begin
    v_based_on := (v_proposal ->> 'based_on_plan_id')::uuid;
    v_day_number := (v_proposal ->> 'day_number')::smallint;
    v_ai_model := (v_proposal ->> 'ai_model')::public.ai_model;
    v_summary := v_proposal ->> 'summary';
    v_changes := v_proposal -> 'changes';
  exception
    when invalid_text_representation or numeric_value_out_of_range
      or invalid_parameter_value or datatype_mismatch then
      raise exception 'invalid proposal' using errcode = 'RM002';
  end;

  select * into v_plan
  from public.workout_plans
  where user_id = v_user_id and archived_at is null;
  if not found or v_plan.id is distinct from v_based_on then
    raise exception 'proposal is out of date' using errcode = 'RM001';
  end if;

  if v_plan.days_per_week is distinct from v_profile.days_per_week then
    raise exception 'profile no longer matches the plan' using errcode = 'RM003';
  end if;

  if v_summary is null
    or char_length(v_summary) not between 3 and 200
    or v_changes is null
    or jsonb_typeof(v_changes) <> 'array'
    or jsonb_array_length(v_changes) not between 1 and 3 then
    raise exception 'invalid proposal' using errcode = 'RM002';
  end if;

  select id into v_day_id
  from public.plan_days
  where plan_id = v_plan.id and day_number = v_day_number;
  if not found then
    raise exception 'day not in plan' using errcode = 'RM002';
  end if;

  begin
    select
      count(*) as total,
      count(distinct c.from_exercise_id) as sources,
      count(distinct c.to_exercise_id) as targets,
      count(*) filter (
        where c.from_exercise_id is null or c.to_exercise_id is null
          or c.sets is null or c.reps is null or c.rest_seconds is null
      ) as incomplete,
      count(pe.id) as in_day,
      count(e.id) filter (where e.equipment <@ v_profile.equipment) as allowed,
      count(*) filter (
        where c.to_exercise_id <> c.from_exercise_id
          and exists (
            select 1 from public.plan_exercises taken
            where taken.day_id = v_day_id and taken.exercise_id = c.to_exercise_id
          )
      ) as taken,
      count(*) filter (
        where c.to_exercise_id <> c.from_exercise_id
          or c.sets <> pe.sets
          or c.reps <> pe.reps
          or c.rest_seconds <> pe.rest_seconds
      ) as changed
    into v_check
    from jsonb_to_recordset(v_changes) as c(
      from_exercise_id text,
      to_exercise_id text,
      sets integer,
      reps text,
      rest_seconds integer
    )
    left join public.plan_exercises pe
      on pe.day_id = v_day_id and pe.exercise_id = c.from_exercise_id
    left join public.exercises e
      on e.id = c.to_exercise_id;
  exception
    when invalid_text_representation or numeric_value_out_of_range
      or invalid_parameter_value or datatype_mismatch then
      raise exception 'invalid proposal' using errcode = 'RM002';
  end;

  if v_check.incomplete > 0
    or v_check.sources <> v_check.total
    or v_check.targets <> v_check.total
    or v_check.in_day <> v_check.total
    or v_check.allowed <> v_check.total
    or v_check.taken > 0
    or v_check.changed = 0 then
    raise exception 'invalid proposal' using errcode = 'RM002';
  end if;

  select jsonb_build_object(
    'title', v_plan.title,
    'ai_model', v_ai_model,
    'instruction', v_summary,
    'days', jsonb_agg(
      jsonb_build_object(
        'day_number', d.day_number,
        'weekday', d.weekday,
        'title', d.title,
        'focus', d.focus,
        'estimated_minutes', d.estimated_minutes,
        'exercises', (
          select jsonb_agg(
            jsonb_build_object(
              'position', pe.position,
              'exercise_id', coalesce(c.to_exercise_id, pe.exercise_id),
              'sets', coalesce(c.sets, pe.sets),
              'reps', coalesce(c.reps, pe.reps),
              'rest_seconds', coalesce(c.rest_seconds, pe.rest_seconds)
            )
            order by pe.position
          )
          from public.plan_exercises pe
          left join jsonb_to_recordset(v_changes) as c(
            from_exercise_id text,
            to_exercise_id text,
            sets integer,
            reps text,
            rest_seconds integer
          )
            on d.id = v_day_id and c.from_exercise_id = pe.exercise_id
          where pe.day_id = d.id
        )
      )
      order by d.day_number
    )
  )
  into v_payload
  from public.plan_days d
  where d.plan_id = v_plan.id;

  v_new_plan_id := public.save_generated_plan(v_payload);

  update public.chat_messages
  set applied_plan_id = v_new_plan_id
  where id = v_message.id;

  return v_new_plan_id;
end;
$$;

revoke execute on function public.apply_coach_proposal(uuid) from public, anon;
grant execute on function public.apply_coach_proposal(uuid) to authenticated;
