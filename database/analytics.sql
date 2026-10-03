-- Neon migration, safe to rerun. Connect as the application database owner.
-- This replaces individual visit tracking with aggregate counters and deletes old visit records.
begin;
create schema if not exists puzzlecub_usage;
revoke all on schema puzzlecub_usage from public;
create table if not exists puzzlecub_usage.usage_limits (
  key text primary key, count integer not null, expires_at timestamptz not null
);
create index if not exists usage_limits_expiry_idx on puzzlecub_usage.usage_limits(expires_at);
create table if not exists puzzlecub_usage.aggregate_daily (
  day date not null,
  page text not null,
  views bigint not null default 0,
  plays bigint not null default 0,
  completions bigint not null default 0,
  active_seconds bigint not null default 0,
  play_seconds bigint not null default 0,
  primary key(day, page)
);
-- Delivery deduplication only. No page, IP, visitor ID or event content is attached.
create table if not exists puzzlecub_usage.aggregate_receipts (
  event_id uuid primary key, expires_at timestamptz not null default now() + interval '10 minutes'
);
create index if not exists aggregate_receipts_expiry_idx on puzzlecub_usage.aggregate_receipts(expires_at);
-- Anonymous heartbeat totals, not a list of connected visitors.
create table if not exists puzzlecub_usage.aggregate_pulses (
  bucket timestamptz not null, game text not null, pulses bigint not null,
  primary key(bucket, game)
);
create table if not exists puzzlecub_usage.aggregate_config (
  singleton boolean primary key default true check(singleton), since timestamptz not null default now()
);
insert into puzzlecub_usage.aggregate_config(singleton) values(true) on conflict do nothing;
alter table puzzlecub_usage.usage_limits enable row level security;
alter table puzzlecub_usage.aggregate_daily enable row level security;
alter table puzzlecub_usage.aggregate_receipts enable row level security;
alter table puzzlecub_usage.aggregate_pulses enable row level security;
alter table puzzlecub_usage.aggregate_config enable row level security;
revoke all on all tables in schema puzzlecub_usage from public;

create or replace function puzzlecub_usage.usage_rate_limit(p_key text, p_limit integer, p_seconds integer)
returns boolean language plpgsql security invoker set search_path = '' as $$
declare attempts integer;
begin
  delete from puzzlecub_usage.usage_limits where expires_at < now();
  insert into puzzlecub_usage.usage_limits as l (key, count, expires_at)
    values (p_key, 1, now() + make_interval(secs => p_seconds))
    on conflict (key) do update set count = l.count + 1 returning count into attempts;
  return attempts <= p_limit;
end;
$$;

create or replace function puzzlecub_usage.aggregate_record(
  p_event uuid, p_page text, p_views integer, p_plays integer, p_completions integer,
  p_seconds integer, p_play_seconds integer, p_pulse boolean
) returns void language plpgsql security invoker set search_path = '' as $$
declare inserted integer; game_id text;
begin
  if p_views not between 0 and 1 or p_plays not between 0 and 1 or p_completions not between 0 and 1
    or p_seconds not between 0 and 30 or p_play_seconds not between 0 and p_seconds then
    raise exception 'Invalid counters';
  end if;
  delete from puzzlecub_usage.aggregate_receipts where expires_at < now();
  delete from puzzlecub_usage.aggregate_pulses where bucket < now() - interval '2 minutes';
  insert into puzzlecub_usage.aggregate_receipts(event_id) values(p_event) on conflict do nothing;
  get diagnostics inserted = row_count;
  if inserted = 0 then return; end if;
  insert into puzzlecub_usage.aggregate_daily as d (day,page,views,plays,completions,active_seconds,play_seconds)
    values ((now() at time zone 'UTC')::date,p_page,p_views,p_plays,p_completions,p_seconds,p_play_seconds)
    on conflict(day,page) do update set views=d.views+p_views, plays=d.plays+p_plays,
      completions=d.completions+p_completions, active_seconds=d.active_seconds+p_seconds, play_seconds=d.play_seconds+p_play_seconds;
  if p_pulse then
    game_id := case p_page when '/alphadoku/classic' then 'alphadoku-classic' when '/alphadoku/mega' then 'alphadoku-mega' when '/chaturang' then 'chaturang' when '/mazewords' then 'mazewords' when '/slide-and-sort' then 'slide-and-sort' when '/mapopia' then 'mapopia' when '/fillthejar' then 'fillthejar' else '' end;
    insert into puzzlecub_usage.aggregate_pulses as p(bucket,game,pulses)
      values(to_timestamp(floor(extract(epoch from now()) / 15) * 15),game_id,1)
      on conflict(bucket,game) do update set pulses=p.pulses+1;
  end if;
end;
$$;

create or replace function puzzlecub_usage.aggregate_report(p_days integer, p_game text default null)
returns jsonb language sql security invoker set search_path = '' as $$
with filtered as (
  select * from puzzlecub_usage.aggregate_daily
  where day >= (now() at time zone 'UTC')::date - (least(greatest(p_days,1),90)-1)
    and (p_game is null or page=case p_game when 'alphadoku-classic' then '/alphadoku/classic' when 'alphadoku-mega' then '/alphadoku/mega' when 'chaturang' then '/chaturang' when 'mazewords' then '/mazewords' when 'slide-and-sort' then '/slide-and-sort' when 'mapopia' then '/mapopia' when 'fillthejar' then '/fillthejar' else 'invalid' end)
), daily as (
  select dates.day::date as day, coalesce(sum(f.views),0) as views, coalesce(sum(f.plays),0) as plays,
    coalesce(sum(f.completions),0) as completions, coalesce(sum(f.active_seconds),0) as active_seconds, coalesce(sum(f.play_seconds),0) as play_seconds
  from generate_series((now() at time zone 'UTC')::date-(least(greatest(p_days,1),90)-1), (now() at time zone 'UTC')::date, interval '1 day') as dates(day)
  left join filtered f on f.day=dates.day::date group by dates.day
), pages as (
  select page,sum(views) as views,sum(plays) as plays,sum(completions) as completions,sum(active_seconds) as active_seconds,sum(play_seconds) as play_seconds
  from filtered group by page
)
select jsonb_build_object(
  'views',coalesce(sum(views),0), 'plays',coalesce(sum(plays),0), 'completions',coalesce(sum(completions),0),
  'activeSeconds',coalesce(sum(active_seconds),0), 'playSeconds',coalesce(sum(play_seconds),0),
  'gameViews',coalesce(sum(views) filter(where page in ('/alphadoku/classic','/alphadoku/mega','/chaturang','/mazewords','/slide-and-sort','/mapopia','/fillthejar')),0),
  'since',(select since from puzzlecub_usage.aggregate_config limit 1),
  'onlineEstimate',(select coalesce(round(sum(pulses)/3.0),0) from puzzlecub_usage.aggregate_pulses where bucket >= to_timestamp(floor(extract(epoch from now())/15)*15)-interval '45 seconds' and bucket < to_timestamp(floor(extract(epoch from now())/15)*15) and (p_game is null or game=p_game)),
  'daily',coalesce((select jsonb_agg(jsonb_build_object('day',day,'views',views,'plays',plays,'completions',completions,'activeSeconds',active_seconds,'playSeconds',play_seconds) order by day) from daily),'[]'::jsonb),
  'pages',coalesce((select jsonb_agg(jsonb_build_object('page',page,'views',views,'plays',plays,'completions',completions,'activeSeconds',active_seconds,'playSeconds',play_seconds) order by views desc,page) from pages),'[]'::jsonb)
) from filtered;
$$;

create or replace function puzzlecub_usage.usage_cleanup()
returns void language sql security invoker set search_path = '' as $$
  delete from puzzlecub_usage.aggregate_daily where day < (now() at time zone 'UTC')::date - 89;
  delete from puzzlecub_usage.aggregate_receipts where expires_at < now();
  delete from puzzlecub_usage.aggregate_pulses where bucket < now() - interval '2 minutes';
  delete from puzzlecub_usage.usage_limits where expires_at < now();
$$;

-- Old deployments/tabs can no longer persist identifying data during rollout.
create or replace function puzzlecub_usage.usage_record(
  p_id uuid, p_ip inet, p_path text, p_referrer text, p_device text,
  p_seconds integer, p_sequence integer, p_games text[], p_completed text[], p_visible boolean
) returns void language plpgsql security invoker set search_path = '' as $$ begin return; end; $$;
create or replace function puzzlecub_usage.usage_report(p_days integer,p_game text default null)
returns jsonb language sql security invoker set search_path = '' as $$
  select '{"visits":[],"total":0,"players":0,"online":0,"averageActiveSeconds":0,"completions":0,"games":[]}'::jsonb;
$$;
drop table if exists puzzlecub_usage.usage_visits;
revoke all on all functions in schema puzzlecub_usage from public;
commit;
