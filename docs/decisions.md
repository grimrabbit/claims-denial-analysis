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
- **Why:** Every gap in the in-scope reason columns is `**` (small-cell suppression). CMS's cell-size policy bars publishing counts of 1–10, and the file matches it: zeros are reported, the smallest positive value is 11, and no cell holds 1–10. The worst-case undercount is 3,016 cells × 10 = 30,160 reasons, 0.04% of 78.6M.
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
