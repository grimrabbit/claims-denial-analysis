-- KFF reports a 19% in-network denial rate for HealthCare.gov insurers in 2024,
-- rounded to the whole percent. Tolerance is half the rounding unit: 0.5 points.
-- Ratio of sums: total denied / total received, across issuers with a reported total.
-- A singular test fails if it returns any rows.

with issuers as (

    select * from {{ ref('stg_tcpuf__issuer_claims') }}
    where denial_total_status = 'reported'

),

rate as (

    select
        100.0 * sum(claims_denied_in_network) / sum(claims_received_in_network) as denial_rate_pct
    from issuers

)

select
    denial_rate_pct,
    19.0 as kff_denial_rate_pct
from rate
where abs(denial_rate_pct - 19.0) > 0.5
