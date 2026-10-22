-- grain: one row per plan x in-network denial reason (22,869 rows)
-- answers Q2 and feeds the Tableau chart: denial reasons by bucket
--
-- deliberately contains NO claims-received or denied-claims totals.
-- each plan has 9 rows here, so any plan-level total would repeat 9 times
-- and summing it would overstate it 9x (fan-out). leaving those columns out
-- means that mistake can't be made from this table.

with reasons as (

    select * from {{ ref('int_plan_denials__by_reason') }}

),

plans as (

    select plan_id, plan_type, metal_level
    from {{ ref('stg_tcpuf__plan_denials') }}

),

issuers as (

    select issuer_id, issuer_name
    from {{ ref('stg_tcpuf__issuer_claims') }}

),

buckets as (

    select reason, bucket_label, bucket_sort
    from {{ ref('denial_reason_buckets') }}

),

final as (

    select
        reasons.plan_reason_id,
        reasons.plan_id,
        reasons.issuer_id,
        issuers.issuer_name,
        reasons.state,
        plans.plan_type,
        plans.metal_level,
        reasons.reason,
        reasons.reason_label,
        reasons.bucket,
        buckets.bucket_label,
        buckets.bucket_sort,
        reasons.denial_reason_count,
        reasons.is_suppressed

    from reasons
    left join plans
        on reasons.plan_id = plans.plan_id
    left join issuers
        on reasons.issuer_id = issuers.issuer_id
    left join buckets
        on reasons.reason = buckets.reason

)

select * from final
