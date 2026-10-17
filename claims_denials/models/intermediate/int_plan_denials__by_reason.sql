-- grain: one row per plan x in-network denial reason
-- 2,541 plans with a reported in-network denial total x 9 reasons = 22,869 rows
-- the out-of-network reason is excluded: it is not an in-network denial (matches KFF)

with plans as (

    select * from {{ ref('stg_tcpuf__plan_denials') }}
    where denial_total_status = 'reported'

),

reason_buckets as (

    select * from {{ ref('denial_reason_buckets') }}

),

reason_columns as (

    -- rename each reason column to the short key used in the seed
    select
        plan_id,
        issuer_id,
        state,
        denied_prior_auth_referral   as prior_auth_referral,
        denied_administrative        as administrative,
        denied_member_not_covered    as member_not_covered,
        denied_services_excluded     as services_excluded,
        denied_medical_necessity     as medical_necessity,
        denied_medical_necessity_bh  as medical_necessity_bh,
        denied_benefit_limit         as benefit_limit,
        denied_experimental          as experimental,
        denied_other                 as other
    from plans

),

unpivoted as (

    -- wide (one column per reason) to long (one row per reason)
    -- include nulls keeps suppressed cells as rows, so every plan has all 9 reasons
    select *
    from reason_columns
    unpivot include nulls (
        denial_reason_count for reason in (
            prior_auth_referral,
            administrative,
            member_not_covered,
            services_excluded,
            medical_necessity,
            medical_necessity_bh,
            benefit_limit,
            experimental,
            other
        )
    )

),

final as (

    select
        unpivoted.plan_id || '__' || unpivoted.reason as plan_reason_id,
        unpivoted.plan_id,
        unpivoted.issuer_id,
        unpivoted.state,
        unpivoted.reason,
        reason_buckets.reason_label,
        reason_buckets.bucket,
        unpivoted.denial_reason_count,
        unpivoted.denial_reason_count is null as is_suppressed
    from unpivoted
    left join reason_buckets
        on unpivoted.reason = reason_buckets.reason

)

select * from final
