-- KFF reports "about 79 million" in-network denial reasons for 2024,
-- excluding the out-of-network reason, rounded to the nearest million.
-- Tolerance is half the rounding unit (see docs/decisions.md, 2026-10-06).
-- A singular test fails if it returns any rows.

select
    sum(denial_reason_count) as total_reasons,
    79000000 as kff_total_reasons
from {{ ref('int_plan_denials__by_reason') }}
having abs(sum(denial_reason_count) - 79000000) > 500000
