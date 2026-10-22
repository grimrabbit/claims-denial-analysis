-- grain: one row per issuer with a reported in-network denial total (158 rows)
-- answers Q4: what happens after a denial? resubmissions (provider action)
-- and internal / external appeals (enrollee action)
-- counts only; rates are computed in analyses/q4_after_denial.sql using
-- matched sets (issuers that report both the numerator and the denominator)

with issuers as (

    select * from {{ ref('stg_tcpuf__issuer_claims') }}
    where denial_total_status = 'reported'

),

final as (

    select
        issuer_id,
        state,
        issuer_name,
        claims_received_in_network >= 1000 as meets_volume_minimum,

        -- denials
        claims_denied_in_network,
        claims_denied_out_of_network,
        claims_denied_in_network + claims_denied_out_of_network as claims_denied_total,

        -- provider action
        claims_resubmitted_in_network,

        -- enrollee action
        internal_appeals_filed,
        internal_appeals_overturned,
        external_appeals_filed,
        external_appeals_overturned,

        -- which ratios this issuer can contribute to (both sides reported)
        claims_resubmitted_in_network is not null                         as has_resubmission_data,
        internal_appeals_filed is not null
            and claims_denied_out_of_network is not null                  as has_appeal_rate_data,
        internal_appeals_filed is not null
            and internal_appeals_overturned is not null                   as has_appeal_outcome_data

    from issuers

)

select * from final
