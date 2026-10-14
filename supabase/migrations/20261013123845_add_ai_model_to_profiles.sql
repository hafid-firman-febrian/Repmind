create type public.ai_model as enum ('gemini_flash', 'gemini_flash_lite', 'gemini_pro');

alter table public.profiles
  add column ai_model public.ai_model not null default 'gemini_flash';
