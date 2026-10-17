-- grain: one row per issuer (185 rows)
-- HIOS issuer IDs are state-specific, so one issuer_id = one issuer in one state.
-- The source repeats issuer columns on every plan row; select distinct collapses
-- them. If CMS ever reports conflicting values for the same issuer, distinct
-- returns two rows for that issuer and the unique test on issuer_id fails.

with source as (

    select * from {{ source('tcpuf', 'ind_qhp') }}

),

issuer_rows as (

    select distinct
        issuer_id,
        state,
        issuer_name,
        "Is_Issuer_New_to_Exchange?(Yes_or_No)" as is_new_issuer_flag,
        issuer_claims_received_in_network,
        issuer_claims_received_out_of_network,
        issuer_claims_denied_in_network,
        issuer_claims_denied_out_of_network,
        issuer_claims_resubmitted_in_network,
        issuer_claims_resubmitted_out_of_network,
        issuer_internal_appeals_filed,
        issuer_number_internal_appeals_overturned,
        issuer_external_appeals_filed,
        issuer_number_external_appeals_overturned

    from source

),

renamed as (

    select
        -- identifiers
        issuer_id,
        state,
        issuer_name,
        is_new_issuer_flag = 'Yes' as is_new_to_exchange,

        -- how the in-network denial total was reported
        case
            when try_cast(issuer_claims_denied_in_network as bigint) is not null then 'reported'
            when issuer_claims_denied_in_network = '**' then 'suppressed'
            when issuer_claims_denied_in_network = 'N/A' then 'new_issuer'
            else 'other'
        end as denial_total_status,

        -- claim volumes
        try_cast(issuer_claims_received_in_network as bigint)       as claims_received_in_network,
        try_cast(issuer_claims_received_out_of_network as bigint)   as claims_received_out_of_network,
        try_cast(issuer_claims_denied_in_network as bigint)         as claims_denied_in_network,
        try_cast(issuer_claims_denied_out_of_network as bigint)     as claims_denied_out_of_network,
        try_cast(issuer_claims_resubmitted_in_network as bigint)    as claims_resubmitted_in_network,
        try_cast(issuer_claims_resubmitted_out_of_network as bigint) as claims_resubmitted_out_of_network,

        -- appeals (filed by enrollees, not providers)
        try_cast(issuer_internal_appeals_filed as bigint)              as internal_appeals_filed,
        try_cast(issuer_number_internal_appeals_overturned as bigint)  as internal_appeals_overturned,
        try_cast(issuer_external_appeals_filed as bigint)              as external_appeals_filed,
        try_cast(issuer_number_external_appeals_overturned as bigint)  as external_appeals_overturned

    from issuer_rows

)

select * from renamed
