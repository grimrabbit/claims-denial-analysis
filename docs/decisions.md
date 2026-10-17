# Decision Log

One entry per non-obvious choice. Format: date, decision, why, alternative considered.

## 2026-10-03: Definition of "preventable" denials
- **Decision:** Preventable = administrative + prior authorization / referral denials. Not preventable = services excluded, benefit limit, medical necessity, experimental. "Other" is unclassified and reported separately.
- **Why:** Billing teams prevent these upstream through correct registration, clean claim submission, timely filing, and prior auth tracking. The rest are plan-design or clinical issues a provider can't fix. The CMS PY24 data dictionary confirms the referral column includes prior authorization. This is my definition, not CMS's.
- **Alternative:** Count medical necessity as partly preventable (documentation quality). Rejected because the public data can't separate documentation failures from true clinical denials.

## 2026-10-05: Ind QHP tab only
- **Decision:** Use only the Individual QHP tab. Exclude Ind SADP (stand-alone dental) and SHOP (small group).
- **Why:** The headline is about medical claims in the individual Marketplace, and KFF uses the same scope, so the reconciliation compares like with like.
- **Alternative:** Include SHOP for more volume. Rejected because it mixes employer coverage into an individual-market finding and breaks the match to KFF.

## 2026-10-05: Denominator is the sum of denial reasons, excluding out-of-network
- **Decision:** Reason shares are computed as each reason's total divided by the sum of all in-network reasons (78.61M), excluding the out-of-network reason. The headline unit is "% of denial reasons," never "% of denials."
- **Why:** Insurers can record more than one reason per denied claim. Reasons exceed reported denied claims in 989 of 1,004 fully reported plans (87.2M reasons vs. 65.6M denied claims overall), so shares over denied claims would sum past 100% and double-count claims with two preventable reasons. The out-of-network reason applies to closed-network plans denying out-of-network providers, not in-network denials. KFF uses the same unit and exclusion; my total (78.61M) matches KFF's "about 79 million."
- **Alternative:** Divide by `Plan_Number_Claims_Denied_In_Network`. Rejected because the shares sum to more than 100%.

## 2026-10-05: Suppressed cells treated as missing; all plans kept
- **Decision:** `try_cast` turns `**` into null, `sum()` skips it, and every plan with a reported in-network denial total is kept (2,541 plans).
- **Why:** Every gap in the in-scope reason columns is `**` (small-cell suppression). CMS's cell-size policy bars publishing counts of 1–10, and the file matches it: zeros are reported, the smallest positive value is 11, and no cell holds 1–10. The worst-case undercount is 2,648 in-network reason cells × 10 = 26,480 reasons, 0.03% of 78.6M. (An earlier count of 3,016 cells included the out-of-network reason, which is excluded from the shares.)
- **Alternative:** Keep only plans with all ten reasons reported. Rejected because it drops 1,537 plans and 35.34% of denied claims, and skews toward larger plans.

## 2026-10-05: Q1 from issuer-level columns, deduplicated to issuer × state
- **Decision:** `stg_tcpuf__issuer_claims` selects distinct issuer × state rows before any aggregation, and Q1's denial rates come from those issuer-level columns.
- **Why:** Issuer values repeat identically on every plan row (185 issuer × state groups, all with multiple plan rows), so summing them from raw rows multiplies them by the number of plans. Deduplicated, the totals match KFF: 84.50M denied of 451.25M received, 18.73% vs. KFF's 19%.
- **Alternative:** Roll plan-level rows up to issuer × state. Rejected because plan-level totals sum to 65.58M denied claims vs. 84.50M at the issuer level; 1,618 plans have no plan-level total (1,600 `N/A`, 18 `**`).

## 2026-10-06: "Provider-side preventable," not "front-office preventable"
- **Decision:** The bucket is labeled "provider-side preventable."
- **Why:** Administrative denials include billing-office causes such as duplicate claims and untimely filing. "Front-office" would mislabel part of a category that is 24.95% of reasons. The limitations section notes that administrative also includes coordination of benefits and workers' comp / auto liability, which a provider can't fully prevent and CMS doesn't split out.
- **Alternative:** "Front-office preventable." Rejected as inaccurate for the billing-office causes.

## 2026-10-06: Member-not-covered reported separately, not in the headline
- **Decision:** The headline is 34.24% (administrative + prior auth / referral). Eligibility denials (7.29%) get their own sentence as partly preventable.
- **Why:** Eligibility verification prevents some of these, but Marketplace enrollees with premium subsidies have a 3-month grace period. Insurers can hold claims in months 2 and 3 and deny them if coverage ends retroactively, so a provider can verify active coverage on the date of service and still be denied. The data can't separate the two causes, and the conservative headline is the one that holds up under questioning.
- **Alternative:** Include it, for a 41.53% headline. Rejected because part of the category is outside the provider's control.

## 2026-10-06: Every number is tagged by source
- **Decision:** Each figure in the README, case study, and memo is tagged *(CMS data)*, *(my classification)*, or *(illustrative)*. Illustrative material lives only in shaded callouts and the appendix; memo KPIs sit under a "Proposed KPI (not measured in this data)" header; Tableau shows measured data only.
- **Why:** The preventable share is real data run through my judgment, and the CARC codes and KPIs aren't from the data at all. Readers need to see that boundary without hunting for footnotes.
- **Alternative:** A single disclaimer footnote. Rejected because footnotes get skipped.

## 2026-10-06: Reconciliation tolerance is half of KFF's rounding unit
- **Decision:** A figure passes if it is within half of the unit KFF rounded to: 0.5M for counts KFF gives in millions, 0.5 points for whole-number percentages, exact for counts KFF gives in full.
- **Why:** KFF only publishes rounded figures, so the true value behind "19%" could be anything from 18.5% to 19.49%. Half the rounding unit is the widest gap that still means "consistent with what KFF published." All nine checks pass: 157 insurers (exact), 451.25M received, 84.50M denied, 18.73% rate, 65.58M plan-level denied, 78.61M reasons, 44.40M out-of-network received, 37.10% out-of-network rate, and five reason shares within 0.29 points.
- **Alternative:** A flat 1% relative tolerance. Rejected as arbitrary: it is looser than the rounding for large counts (4.5M on 451M) and tighter than it for small ones.

## 2026-10-07: Staging keeps every plan and flags status instead of filtering
- **Decision:** `stg_tcpuf__plan_denials` keeps all 4,159 Ind QHP plans. A `denial_total_status` column records whether the in-network denial total was reported (2,541), suppressed (18), or missing because the plan is new (1,600). Models downstream filter to `reported`.
- **Why:** Staging is a cleaned, typed copy of the source, one row per source row. Filtering there hides rows from every later model and makes "how many plans did we drop, and why?" impossible to answer from the warehouse. Keeping the status column also preserves the difference between `**` (a small number) and `N/A` (no data), which `try_cast` alone collapses into the same null.
- **Alternative:** Filter to plans with a reported total in staging, as the original plan said. Rejected for the reasons above.

## 2026-10-07: Staging models materialized as tables
- **Decision:** Models under `models/staging/` build as tables (`+materialized: table` in `dbt_project.yml`).
- **Why:** The source is a `read_xlsx` call with a relative path. A view would store that call and re-read the xlsx on every query, and it would break when the database is opened from any folder other than `claims_denials/`, for example the DuckDB command line or an export script run from the repo root. A table stores the typed rows, so the database stands on its own after a build. The data is 4,159 rows, so storage cost is trivial.
- **Alternative:** Views, the dbt default for staging. Rejected because of the path dependency.

## 2026-10-08: Issuer key is issuer_id alone
- **Decision:** `stg_tcpuf__issuer_claims` is keyed and tested on `issuer_id`, not issuer ID × state.
- **Why:** HIOS issuer IDs are assigned per issuer per state. In this file, 185 distinct issuer IDs map to exactly 185 issuer × state pairs, and no ID appears in more than one state. A single-column key is simpler to test and to join on. The unique test fails if that ever stops being true.
- **Alternative:** A combined issuer ID × state key, as the plan originally said. Not needed given the data, and it would add a column only to restate what the ID already encodes.

## 2026-10-08: Collapse issuer rows with select distinct, not group by
- **Decision:** The issuer model uses `select distinct` over the issuer columns, with a unique test on `issuer_id` as the guard.
- **Why:** If CMS reports one issuer with conflicting values on different plan rows, `distinct` returns two rows for that issuer and the unique test fails loudly. `group by issuer_id` with `max()` or `any_value()` would silently pick one value and hide the conflict.
- **Alternative:** `group by` with an aggregate on each column. Rejected because it hides data problems instead of surfacing them.

## 2026-10-08: The bucket classification lives in a seed
- **Decision:** The mapping of the 9 CMS reasons to 4 buckets (provider-side preventable, eligibility, not preventable, unexplained) is a CSV in `seeds/denial_reason_buckets.csv`, joined into the intermediate model, with a one-line basis for each reason.
- **Why:** The mapping is my central analytical judgment, so it should be readable by someone who doesn't read SQL, reviewable in one file, and changeable without editing model code. As a seed it is version-controlled, tested (unique reason; every reason in the data must exist in the seed), and available to Tableau as a table.
- **Alternative:** A CASE statement in the model. Rejected because it buries the classification inside SQL.

## 2026-10-08: Suppressed reason cells stay as rows
- **Decision:** The intermediate model keeps every plan × reason combination, including the 2,648 suppressed cells, with a null count and `is_suppressed = true`.
- **Why:** Every plan then has exactly 9 rows, so the grain is complete and countable, and the suppression rate per reason can be reported. Sums skip the nulls, so the shares are unchanged.
- **Alternative:** Drop null rows during the unpivot (the default behavior). Rejected because it makes suppressed cells invisible.
