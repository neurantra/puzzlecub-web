-- Run once in the Neon SQL editor, connected to the dedicated PuzzleCub database.
-- The application connects as this migration owner. No browser connects to Neon directly.
begin;
create schema if not exists puzzlecub_usage;
revoke all on schema puzzlecub_usage from public;
create table if not exists puzzlecub_usage.usage_visits (
  id uuid primary key,
  started_at timestamptz not null default now(),
  last_seen timestamptz not null default now(),
  ip inet,
  entry_path text not null,
  last_path text not null,
  referrer text not null default '',
  device text not null,
  active_seconds integer not null default 0,
  client_seconds integer not null default 0,
  sequence integer not null default 0,
  games text[] not null default '{}',
  completed_games text[] not null default '{}',
  visible boolean not null default true
);
create index if not exists usage_visits_started_idx on puzzlecub_usage.usage_visits (started_at desc);
create table if not exists puzzlecub_usage.usage_limits (
  key text primary key, count integer not null, expires_at timestamptz not null
);
alter table puzzlecub_usage.usage_visits enable row level security;
alter table puzzlecub_usage.usage_limits enable row level security;
revoke all on puzzlecub_usage.usage_visits, puzzlecub_usage.usage_limits from public;

create or replace function puzzlecub_usage.usage_rate_limit(p_key text, p_limit integer, p_seconds integer)
returns boolean language plpgsql security invoker set search_path = '' as $$
declare attempts integer;
begin
  delete from puzzlecub_usage.usage_limits where expires_at < now();
  insert into puzzlecub_usage.usage_limits as l (key, count, expires_at)
    values (p_key, 1, now() + make_interval(secs => p_seconds))
    on conflict (key) do update set count = l.count + 1
    returning count into attempts;
  return attempts <= p_limit;
end;
$$;

create or replace function puzzlecub_usage.usage_record(
  p_id uuid, p_ip inet, p_path text, p_referrer text, p_device text,
  p_seconds integer, p_sequence integer, p_games text[], p_completed text[], p_visible boolean
) returns void language plpgsql security invoker set search_path = '' as $$
begin
  insert into puzzlecub_usage.usage_visits as v
    (id, ip, entry_path, last_path, referrer, device, client_seconds, sequence, games, completed_games, visible)
  values (p_id, p_ip, p_path, p_path, p_referrer, p_device, p_seconds, p_sequence, p_games, p_completed, p_visible)
  on conflict (id) do update set
    last_seen = now(), last_path = p_path, visible = p_visible,
    active_seconds = v.active_seconds + least(greatest(0, p_seconds - v.client_seconds), greatest(0, floor(extract(epoch from now() - v.last_seen))::integer), 30),
    client_seconds = greatest(v.client_seconds, p_seconds), sequence = p_sequence,
    games = array(select distinct unnest(v.games || p_games)),
    completed_games = array(select distinct unnest(v.completed_games || p_completed))
  where p_sequence > v.sequence;
end;
$$;

create or replace function puzzlecub_usage.usage_report(p_days integer, p_game text default null)
returns jsonb language sql security invoker set search_path = '' as $$
with filtered as (
  select *, (visible and last_seen > now() - interval '45 seconds') as online
  from puzzlecub_usage.usage_visits
  where started_at >= now() - make_interval(days => least(greatest(p_days, 1), 90))
    and (p_game is null or p_game = any(games))
), recent as (select * from filtered order by started_at desc limit 500),
game_stats as (
  select g.id, count(*) as players, count(*) filter (where g.id = any(f.completed_games)) as completions
  from filtered f cross join lateral unnest(f.games) as g(id) group by g.id
)
select jsonb_build_object(
  'total', count(*),
  'players', count(*) filter (where cardinality(games) > 0),
  'online', count(*) filter (where online),
  'averageActiveSeconds', coalesce(round(avg(active_seconds)), 0),
  'completions', coalesce(sum(cardinality(completed_games)), 0),
  'games', coalesce((select jsonb_agg(jsonb_build_object('id', id, 'players', players, 'completions', completions) order by players desc) from game_stats), '[]'::jsonb),
  'visits', coalesce((select jsonb_agg(jsonb_build_object(
    'id', id, 'startedAt', started_at, 'lastSeen', last_seen, 'ip', case when started_at >= now() - interval '7 days' then host(ip) else null end,
    'entryPath', entry_path, 'lastPath', last_path, 'referrer', referrer, 'device', device,
    'activeSeconds', active_seconds, 'games', games, 'completedGames', completed_games, 'online', online
  ) order by started_at desc) from recent), '[]'::jsonb)
) from filtered;
$$;

create or replace function puzzlecub_usage.usage_cleanup()
returns void language sql security invoker set search_path = '' as $$
  update puzzlecub_usage.usage_visits set ip = null where started_at < now() - interval '7 days' and ip is not null;
  delete from puzzlecub_usage.usage_visits where started_at < now() - interval '90 days';
  delete from puzzlecub_usage.usage_limits where expires_at < now();
$$;

revoke all on function puzzlecub_usage.usage_rate_limit(text, integer, integer), puzzlecub_usage.usage_record(uuid, inet, text, text, text, integer, integer, text[], text[], boolean), puzzlecub_usage.usage_report(integer, text), puzzlecub_usage.usage_cleanup() from public;
commit;
