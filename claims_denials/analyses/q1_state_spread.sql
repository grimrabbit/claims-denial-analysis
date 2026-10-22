-- Q1: within each state, the gap between the highest and lowest issuer denial rate
-- (qualifying issuers only), summarized across states

with comparison_issuers as (

    select * from {{ ref('fct_issuer_denial_rates') }}
    where is_in_q1_comparison

),

state_spread as (

    select
        state,
        count(*) as issuers,
        100 * (max(denial_rate) - min(denial_rate)) as spread_pts
    from comparison_issuers
    group by state

)

select
    count(*)                         as states,
    sum(issuers)                     as issuers,
    round(median(spread_pts), 1)     as median_spread_pts,
    round(min(spread_pts), 1)        as min_spread_pts,
    round(max(spread_pts), 1)        as max_spread_pts
from state_spread
