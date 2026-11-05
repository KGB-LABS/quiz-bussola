-- Desafio da Bússola: liberação controlada pelo chefe
-- Rodar uma vez no SQL Editor do Supabase.

-- 1) Estado do desafio (uma única linha)
create table if not exists public.quiz_bussola_estado (
  id            smallint primary key default 1 check (id = 1),
  liberado      boolean     not null default false,
  liberado_em   timestamptz,
  atualizado_em timestamptz not null default now()
);
insert into public.quiz_bussola_estado (id) values (1) on conflict (id) do nothing;

alter table public.quiz_bussola_estado enable row level security;

drop policy if exists "estado legivel por todos" on public.quiz_bussola_estado;
create policy "estado legivel por todos"
  on public.quiz_bussola_estado for select
  to anon, authenticated
  using (true);
-- Sem policy de insert/update/delete: só a função abaixo altera o estado.

grant select on public.quiz_bussola_estado to anon, authenticated;

-- 2) Liberar / encerrar (somente admin ou master do site)
create or replace function public.quiz_bussola_liberar(_liberado boolean)
returns public.quiz_bussola_estado
language plpgsql
security definer
set search_path = public
as $$
declare
  r public.quiz_bussola_estado;
begin
  if not (coalesce(public.is_master(), false) or coalesce(public.is_admin(), false)) then
    raise exception 'Apenas administradores podem liberar o desafio.' using errcode = '42501';
  end if;

  update public.quiz_bussola_estado
     set liberado      = _liberado,
         liberado_em   = case when _liberado then now() else liberado_em end,
         atualizado_em = now()
   where id = 1
  returning * into r;

  return r;
end;
$$;

revoke all on function public.quiz_bussola_liberar(boolean) from public, anon;
grant execute on function public.quiz_bussola_liberar(boolean) to authenticated;

-- 3) Trava no servidor: recusa respostas com o desafio fechado,
--    mesmo que alguém chame a RPC quiz_bussola_enviar direto.
create or replace function public.quiz_bussola_bloqueio()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if not coalesce((select liberado from public.quiz_bussola_estado where id = 1), false) then
    raise exception 'O desafio ainda não foi liberado pelo chefe.' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

drop trigger if exists quiz_bussola_bloqueio on public.quiz_bussola_respostas;
create trigger quiz_bussola_bloqueio
  before insert on public.quiz_bussola_respostas
  for each row execute function public.quiz_bussola_bloqueio();
