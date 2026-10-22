-- Q4: what happens after a denial?
-- Suppressed counts (**) are real values from 1 to 10. Rather than drop those
-- issuers or treat the values as 0, each ratio is computed twice: once with
-- every suppressed numerator at 1 (low) and once at 10 (high). The true value
-- lies between. Issuers whose denominator is suppressed or missing are left out.

with issuers as (

    select * from {{ ref('fct_issuer_appeals') }}

),

resubmissions as (

    select
        'resubmissions per 100 in-network denials' as metric,
        count(*) as issuers,
        100.0 * sum(coalesce(claims_resubmitted_in_network, 1)) / sum(claims_denied_in_network)  as low,
        100.0 * sum(coalesce(claims_resubmitted_in_network, 10)) / sum(claims_denied_in_network) as high
    from issuers

),

appeal_rate as (

    select
        'internal appeals per 100 denials (in- and out-of-network)' as metric,
        count(*) as issuers,
        100.0 * sum(coalesce(internal_appeals_filed, 1)) / sum(claims_denied_total)  as low,
        100.0 * sum(coalesce(internal_appeals_filed, 10)) / sum(claims_denied_total) as high
    from issuers
    where claims_denied_total is not null

),

appeal_outcomes as (

    select
        '% of internal appeals overturned' as metric,
        count(*) as issuers,
        100.0 * sum(coalesce(internal_appeals_overturned, 1)) / sum(internal_appeals_filed)  as low,
        100.0 * sum(coalesce(internal_appeals_overturned, 10)) / sum(internal_appeals_filed) as high
    from issuers
    where internal_appeals_filed is not null

),

combined as (

    select * from resubmissions
    union all
    select * from appeal_rate
    union all
    select * from appeal_outcomes

)

select
    metric,
    issuers,
    round(low, 2)  as low,
    round(high, 2) as high
from combined
