--Задание 1
--Проверяем общее количество записей 
select count(*) from oplogs

--Проверяем количество уникальных записей по всем полям 
select count(distinct platform_type,
                      user_id,
                      session_id,
                      user_time, 
                      country, 
                      version, 
                      event_name, 
                      param_1, 
                      param_2,
                      extra_1,
                      extra_2,
                      level)
from oplogs

--Находим дубликаты по ключевым полям 
select user_id, session_id, user_time, event_name, count(*) as duplicates
from oplogs 
group by user_id, session_id, user_time, event_name 
having count(*) > 1

--Cоздадим новую чистую таблицу
create table oplogs_clean as
select distinct platform_type,
                user_id,
                session_id,
                user_time, 
                country, 
                version, 
                event_name, 
                param_1, 
                param_2,
                extra_1,
                extra_2,
                level
from oplogs

select * from oplogs_clean
select count(*) from oplogs_clean

               
--Создаем таблицу user_info
create table user_info (
   platform_type String, 
   user_id String, 
   country String, 
   first_version String, 
   last_version String, 
   type_traffic String, 
   first_time DateTime,
   last_time DateTime,
   dates Array(Date),
   payer UInt8,
   total_revenue Float64, 
   max_level UInt16, 
   amount_gold UInt32, 
   amount_bronze_cup UInt16, 
   amount_silver_cup UInt16, 
   amount_gold_cup UInt16
) engine = MergeTree()
order by user_id

--Создаем таблицу user_session
create table user_session (
   platform_type String, 
   user_id String, 
   session_id String,
   version String, 
   session_number UInt16, 
   time_start_session DateTime, 
   time_finish_session DateTime, 
   length_session UInt32, 
   amount_get_level UInt16, 
   amount_get_gold UInt32, 
   amount_get_bronze_cup UInt16, 
   amount_get_silver_cup UInt16, 
   amount_get_gold_cup UInt16
) engine = MergeTree()
order by (user_id, session_id) 

--Создаем таблицу user_payments
create table user_payments (
   platform_type String, 
   user_id String, 
   session_id String, 
   version String, 
   purchase_number UInt16, 
   purchase_time DateTime, 
   item String,
   offer_id String, 
   price Float64, 
   level UInt16
) engine = MergeTree()
order by (user_id, purchase_time)


--Заполняем таблицу user_info
insert into user_info
select platform_type,
       user_id,
       country,
       argMin(version, parseDateTime32BestEffort(user_time)) as first_version,
       argMax(version, parseDateTime32BestEffort(user_time)) as last_version,
       anyIf(extra_1, event_name = 'app_install_start') as type_trafic,
       min(parseDateTime32BestEffort(user_time)) as first_time,
       max(parseDateTime32BestEffort(user_time)) as last_time,
       groupUniqArray(parseDateTime32BestEffort(user_time)) as dates,
       if(countIf(event_name = 'purchase' and param_1 = 1) > 0, 1, 0) as payer,
       sumIf(param_2, event_name = 'purchase' and param_1 = 1) as total_revenue,
       max(level) as max_level,
       argMaxIf(param_2, parseDateTime32BestEffort(user_time), event_name in 
       ('res_movement_inc', 'res_movement_out') and extra_1 = 'gold') as amount_gold,
       countIf(event_name = 'stage_win' and extra_2 = 'bronze_cup') as amount_bronze_cup,
       countIf(event_name = 'stage_win' and extra_2 = 'silver_cup') as amount_silver_cup,
       countIf(event_name = 'stage_win' and extra_2 = 'gold_cup') as amount_gold_cup
from oplogs_clean
group by platform_type, user_id, country

select * from user_info


--Заполняем таблицу user_session
insert into user_session
with session_info as (
select platform_type,
       user_id, 
       session_id, 
       any(version) as version, 
       minIf(parseDateTime32BestEffort(assumeNotNull(user_time)), event_name = 'loading_finish') as time_start_session,
       max(parseDateTime32BestEffort(assumeNotNull(user_time))) as time_finish_session,
       countIf(event_name = 'lvl_up') as amount_get_level,
       sumIf(param_1, event_name = 'res_movement_inc' and extra_1 = 'gold') as amount_get_gold,
       countIf(event_name = 'stage_win' and extra_2 = 'bronze_cup') as amount_get_bronze_cup,
       countIf(event_name = 'stage_win' and extra_2 = 'silver_cup') as amount_get_silver_cup,
       countIf(event_name = 'stage_win' and extra_2 = 'gold_cup') as amount_get_gold_cup
from oplogs_clean
where user_time is not null and user_time != ''
group by platform_type, user_id, session_id)
select platform_type,
       user_id, 
       session_id, 
       version, 
       row_number() over (partition by user_id order by time_start_session) as session_number,
       time_start_session, 
       time_finish_session,
       dateDiff('second', time_start_session, time_finish_session) as length_session,
       amount_get_level, 
       amount_get_gold,
       amount_get_bronze_cup,
       amount_get_silver_cup,
       amount_get_gold_cup
from session_info

select * from user_session

--Заполняем таблицу user_payments
insert into user_payments
select platform_type, 
       user_id, 
       session_id, 
       version, 
       row_number() over (partition by user_id order by parseDateTime32BestEffort(user_time)) as purchase_number, 
       parseDateTime32BestEffort(user_time) as purchase_time, 
       extra_1 as item, 
       extra_2 as offer_id, 
       param_2 as price, 
       level as level
from oplogs_clean
where event_name = 'purchase' and param_1 = 1 

select * from user_payments


--Задание 2
--Система метрик

--Для выгрузки 
--user_info_full
select user_id,
       country,
       platform_type,
       type_traffic,
       payer,
       total_revenue,
       max_level,
       amount_gold,
       amount_bronze_cup,
       amount_silver_cup,
       amount_gold_cup,
       first_time as install_date
from user_info

--user_session_full
select user_id,
       session_id,
       session_number,
       platform_type,
       time_start_session,
       time_finish_session,
       length_session,
       amount_get_level,
       amount_get_gold
from user_session

--retention_detail
with user_activity as (
    select 
        user_id,
        toDate(first_time) as install_date,
        arrayMap(x -> toDate(x), dates) as active_dates
    from user_info
)
select 
    user_id,
    install_date,
    case when has(active_dates, install_date + 1) then 1 else 0 end as d1_active,
    case when has(active_dates, install_date + 3) then 1 else 0 end as d3_active,
    case when has(active_dates, install_date + 7) then 1 else 0 end as d7_active,
    case when has(active_dates, install_date + 14) then 1 else 0 end as d14_active
from user_activity

--funnel_tutorial_detail
select user_id,
       param_1 as step_number
from oplogs_clean
where event_name = 'tutorial_step_finish'
order by user_id, step_number

--daily_activity
select parseDateTime32BestEffort(user_time) as event_date,
       count(*) as events,
       count(distinct user_id) as active_users,
       count(distinct session_id) as sessions
from oplogs_clean
group by event_date
order by event_date

--funnel_first_session
with first_sessions as (
select toString(user_id) as user_id, 
       session_id
from user_session
where session_number = 1
),
first_session_users as (
select toString(o.user_id) as user_id,
       max(case when o.event_name = 'app_install_start' then 1 else 0 end) as has_install,
       max(case when o.event_name = 'loading_finish' and fs.session_id is not null then 1 else 0 end) as has_load,
       max(case when o.event_name = 'tutorial_step_start' and fs.session_id is not null then 1 else 0 end) as has_tutorial_start,
       max(case when o.event_name = 'tutorial_step_finish' and o.param_1 = 7 and fs.session_id is not null then 1 else 0 end) as has_tutorial_finish,
       max(case when o.event_name = 'stage_start' and o.param_1 = 1 and o.param_2 = 1 and fs.session_id is not null then 1 else 0 end) as has_level_start,
       max(case when o.event_name = 'stage_win' and o.param_1 = 1 and o.param_2 = 1 and fs.session_id is not null then 1 else 0 end) as has_level_win
from oplogs_clean o
left join first_sessions fs 
on toString(o.user_id) = fs.user_id 
and o.session_id = fs.session_id
group by toString(o.user_id)
),
total as (
select count(distinct user_id) as total_users 
from first_session_users
)
select '1. установка' as step,
       (select total_users from total) as users,
       100.0 as conversion_pct
from total
union all
select '2. загрузка (1-я сессия)',
       count(case when has_load = 1 then 1 end),
       round(count(case when has_load = 1 then 1 end) * 100.0 / (select total_users from total), 2)
from first_session_users
union all
select '3. старт тутора',
       count(case when has_tutorial_start = 1 then 1 end),
       round(count(case when has_tutorial_start = 1 then 1 end) * 100.0 / (select total_users from total), 2)
from first_session_users
union all
select '4. финиш тутора (шаг 7)',
       count(case when has_tutorial_finish = 1 then 1 end),
       round(count(case when has_tutorial_finish = 1 then 1 end) * 100.0 / (select total_users from total), 2)
from first_session_users
union all
select '5. старт 1-го уровня',
       count(case when has_level_start = 1 then 1 end),
       round(count(case when has_level_start = 1 then 1 end) * 100.0 / (select total_users from total), 2)
from first_session_users
union all
select '6. победа в 1-м уровне',
       count(case when has_level_win = 1 then 1 end),
       round(count(case when has_level_win = 1 then 1 end) * 100.0 / (select total_users from total), 2)
from first_session_users

--Выгрузка данных для A/B-теста
with tutorial_progress as (
    select user_id,
           max(case when event_name = 'tutorial_step_finish' then param_1 else 0 end) as max_step,
           count(distinct session_id) as sessions,
           count(*) as events
    from oplogs_clean
    where parseDateTime32BestEffort(user_time) between '2023-02-01' and '2023-02-07'
    and event_name in ('tutorial_step_start', 'tutorial_step_finish')
    group by user_id
)
select user_id,
       max_step,
       --Определяем группу (четный - A, нечетный - B)
       case when user_id % 2 = 0 then 'A' else 'B' end as group,
       -- Прошёл ли тутор (все 7 шагов)
       case when max_step = 7 then 1 else 0 end as finished_tutorial,
       sessions,
       events
from tutorial_progress
where user_id is not null 
order by user_id




