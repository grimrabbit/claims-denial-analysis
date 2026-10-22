-- Q4: what happens after a denial?
-- each ratio uses a matched set: only issuers that report both sides of it

with issuers as (

    select * from {{ ref('fct_issuer_appeals') }}

),

resubmissions as (

    select
        count(*) as issuers,
        round(100.0 * sum(claims_resubmitted_in_network) / sum(claims_denied_in_network), 1)
            as resubmissions_per_100_in_network_denials
    from issuers
    where has_resubmission_data

),

appeal_rate as (

    select
        count(*) as issuers,
        sum(internal_appeals_filed) as internal_appeals_filed,
        round(100.0 * sum(internal_appeals_filed) / sum(claims_denied_total), 2)
            as internal_appeals_per_100_denials
    from issuers
    where has_appeal_rate_data

),

appeal_outcomes as (

    select
        count(*) as issuers,
        round(100.0 * sum(internal_appeals_overturned) / sum(internal_appeals_filed), 1)
            as pct_internal_appeals_overturned
    from issuers
    where has_appeal_outcome_data

)

select
    resubmissions.issuers   as resubmission_issuers,
    resubmissions.resubmissions_per_100_in_network_denials,
    appeal_rate.issuers     as appeal_rate_issuers,
    appeal_rate.internal_appeals_filed,
    appeal_rate.internal_appeals_per_100_denials,
    appeal_outcomes.issuers as appeal_outcome_issuers,
    appeal_outcomes.pct_internal_appeals_overturned
from resubmissions
cross join appeal_rate
cross join appeal_outcomes
