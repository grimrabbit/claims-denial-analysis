-- grain: one row per plan (Individual Marketplace medical QHPs, PY2024 claims)
-- all 4,159 plans are kept; downstream models filter on denial_total_status

with source as (

    select * from {{ source('tcpuf', 'ind_qhp') }}

),

renamed as (

    select
        -- identifiers
        plan_id,
        issuer_id,
        state,
        plan_type,
        metal_level,

        -- how the in-network denial total was reported
        case
            when try_cast(plan_number_claims_denied_in_network as bigint) is not null then 'reported'
            when plan_number_claims_denied_in_network = '**' then 'suppressed'
            when plan_number_claims_denied_in_network = 'N/A' then 'new_plan'
            else 'other'
        end as denial_total_status,

        -- claim volumes (legend codes become null)
        try_cast(plan_number_claims_received_in_network as bigint)      as claims_received_in_network,
        try_cast(plan_number_claims_received_out_of_network as bigint)  as claims_received_out_of_network,
        try_cast(plan_number_claims_denied_in_network as bigint)        as claims_denied_in_network,
        try_cast(plan_number_claims_denied_out_of_network as bigint)    as claims_denied_out_of_network,

        -- denial reasons (in-network; one claim can carry several reasons)
        try_cast(plan_number_claims_denied_referral_required as bigint)                                    as denied_prior_auth_referral,
        try_cast(plan_number_claims_denied_due_to_administrative_reason as bigint)                         as denied_administrative,
        try_cast(plan_number_claims_denied_due_to_member_not_covered as bigint)                            as denied_member_not_covered,
        try_cast(plan_number_claims_denied_services_excluded as bigint)                                    as denied_services_excluded,
        try_cast(plan_number_claims_denied_not_medically_necessary_excluding_behavioral_health as bigint)   as denied_medical_necessity,
        try_cast(plan_number_claims_denied_not_medically_necessary_behavioral_health_only as bigint)       as denied_medical_necessity_bh,
        try_cast(plan_number_claims_denied_due_to_enrolle_benefit_limit_reached as bigint)                 as denied_benefit_limit,
        try_cast(plan_number_claims_denied_due_to_investigational_experimental_cosmetic_proceduce as bigint) as denied_experimental,
        try_cast(plan_number_claims_denied_other as bigint)                                                as denied_other,
        try_cast(plan_number_claims_denied_due_to_out_of_network as bigint)                                as denied_out_of_network_reason

    from source

)

select * from renamed
