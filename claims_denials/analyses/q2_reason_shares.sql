-- Q2 headline: share of in-network denial reasons by bucket
-- ratio of sums: total reasons per bucket / total reasons overall

select
    bucket,
    sum(denial_reason_count) as denial_reasons,
    round(100.0 * sum(denial_reason_count) / sum(sum(denial_reason_count)) over (), 2) as pct_of_reasons
from {{ ref('int_plan_denials__by_reason') }}
group by bucket
order by denial_reasons desc
