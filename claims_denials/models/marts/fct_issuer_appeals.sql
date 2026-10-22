-- grain: one row per issuer with a reported in-network denial total (158 rows)
-- answers Q4: what happens after a denial? resubmissions (provider action)
-- and internal / external appeals (enrollee action)
-- counts only; ratios are computed in analyses/q4_after_denial.sql, with
-- suppressed values (1-10) bounded rather than dropped or set to 0

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
        external_appeals_overturned

    from issuers

)

select * from final
