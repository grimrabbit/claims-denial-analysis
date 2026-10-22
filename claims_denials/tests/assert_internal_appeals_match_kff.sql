-- KFF reports "at least 262,982" internal appeals for 2024, a full count
-- rather than a rounded one, so the tolerance is zero (see docs/decisions.md, 2026-10-06).
-- A singular test fails if it returns any rows.

select
    sum(internal_appeals_filed) as internal_appeals_filed,
    262982 as kff_internal_appeals_filed
from {{ ref('fct_issuer_appeals') }}
having sum(internal_appeals_filed) != 262982
