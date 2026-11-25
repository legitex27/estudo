-- Estudo · schema Supabase (free tier)
-- Rode isto no SQL Editor do seu projeto Supabase.
-- Tabela única: um JSON por usuário. Simples, barato e suficiente pro MVP.

create table if not exists public.estados (
  user_id     uuid primary key references auth.users(id) on delete cascade,
  data        jsonb not null default '{}'::jsonb,
  updated_at  timestamptz not null default now()
);

-- Mantém updated_at coerente em cada escrita
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_estados_touch on public.estados;
create trigger trg_estados_touch
before update on public.estados
for each row execute function public.touch_updated_at();

-- RLS: cada usuário só enxerga e escreve a própria linha
alter table public.estados enable row level security;

drop policy if exists "ler proprio estado"    on public.estados;
drop policy if exists "criar proprio estado"  on public.estados;
drop policy if exists "editar proprio estado" on public.estados;

create policy "ler proprio estado"
  on public.estados for select
  using (auth.uid() = user_id);

create policy "criar proprio estado"
  on public.estados for insert
  with check (auth.uid() = user_id);

create policy "editar proprio estado"
  on public.estados for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
