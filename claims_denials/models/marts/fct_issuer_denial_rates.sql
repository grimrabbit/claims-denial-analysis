-- grain: one row per issuer with a reported in-network denial total (158 rows)
-- answers Q1: how much do in-network denial rates differ between issuers in the same state?
-- an issuer is in the Q1 comparison if it has 1,000+ in-network claims (KFF's minimum)
-- and at least one other qualifying issuer in its state

with issuers as (

    select * from {{ ref('stg_tcpuf__issuer_claims') }}
    where denial_total_status = 'reported'

),

flagged as (

    select
        issuer_id,
        state,
        issuer_name,
        claims_received_in_network,
        claims_denied_in_network,

        -- this issuer's own rate: valid at this grain, never average it across issuers
        claims_denied_in_network::double / claims_received_in_network as denial_rate,

        claims_received_in_network >= 1000 as meets_volume_minimum

    from issuers

),

with_state_context as (

    select
        *,

        -- window functions: compute across all qualifying issuers in the same state,
        -- while keeping one row per issuer
        count(*) filter (where meets_volume_minimum)
            over (partition by state) as qualifying_issuers_in_state,

        sum(claims_denied_in_network) filter (where meets_volume_minimum)
            over (partition by state)
        / sum(claims_received_in_network) filter (where meets_volume_minimum)
            over (partition by state) as state_denial_rate

    from flagged

),

final as (

    select
        issuer_id,
        state,
        issuer_name,
        claims_received_in_network,
        claims_denied_in_network,
        denial_rate,
        meets_volume_minimum,
        qualifying_issuers_in_state,
        meets_volume_minimum and qualifying_issuers_in_state >= 2 as is_in_q1_comparison,
        state_denial_rate,
        denial_rate - state_denial_rate as rate_vs_state

    from with_state_context

)

select * from final
