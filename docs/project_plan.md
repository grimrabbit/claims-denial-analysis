# Claims Denial Analysis — Project Plan

Created Oct 3, 2026 · Updated Oct 21, 2026 (Q1 and Q4 marts built) · @Danny

## Purpose

This project asks one question about claim denials, answers it with numbers that can be defended, and ends in recommendations a billing manager could act on. A small, tested dbt pipeline proves the numbers are trustworthy; it supports the analysis rather than being the main event. A fuller analytics engineering build is v2.

It is written for three readers, each layer standing on its own: a 60-second skim of the README and dashboard, a full read of the case study, and a line-by-line review of the SQL. The validated number is the product; the chart illustrates it.

## Business questions

v1 answers three questions from one dataset. The headline is: **where do Marketplace claim denials concentrate, and how much is the kind a provider could prevent?** It speaks directly to claims and billing roles and can be answered with real data.

| # | Question | Dataset | Scope |
| --- | --- | --- | --- |
| Q2 | What share of in-network denial reasons falls in each category, and how much could a provider prevent? | Transparency in Coverage | v1 must-have (headline) |
| Q1 | Among issuers with at least 1,000 in-network claims, how wide is the spread in final in-network denial rates within the same state? | Transparency in Coverage | v1 supporting |
| Q4 | What happens after a denial: how often are claims resubmitted, how often do enrollees appeal, and how many appeals succeed? | Transparency in Coverage | v1 nice-to-have |
| Q3 | How have denial rates moved across plan years? | Transparency in Coverage, 2+ years | v2 |
| Q5 | When a denial reaches independent review, which treatment categories are most often overturned? | California review decisions | v2 |
| Q6 | Does the denial type (medical necessity, experimental, urgent care) change the odds of an overturn? | California review decisions | v2 |
| Q7 | Do HMO and PPO plans, or metal levels, differ in prior authorization denial share? | Transparency in Coverage + Plan Attributes | v2 |
| Q8 | What themes appear in the written case findings? | California review decisions | Cut |

**Priority if time runs short:** Q2 is the must-have, Q1 supports it, and Q4 is the first cut if M5 slips.

**Q1 method:** apply KFF's 1,000-claim minimum, then report the spread as a distribution, never as named highest and lowest issuers. Percentiles within a state don't work: 157 issuer × state groups pass the minimum across 30 states, with a median of 5 issuers per state, 13 states with 3 or fewer, and 1 state with a single issuer. The metric is each state's gap between its highest and lowest issuer rate (states with 2+ issuers), summarized as the median gap across states. Confirmed in dbt Oct 21 (`fct_issuer_denial_rates` + `analyses/q1_state_spread.sql`): 156 issuers in 29 states; median gap 12.4 percentage points, ranging from 1.1 to 24.0. Excluded: 2 issuers under 1,000 claims, and Wyoming (one qualifying issuer). Writing up Q1 remains for M5.

**Q4 framing:** resubmissions are a provider action; appeals are filed by enrollees (the CMS dictionary defines them as requests by the insured). The resubmission-to-denial ratio is the provider-side number: 32.1M resubmitted in-network claims against 84.5M denied, 38.0% at the issuer level. It is a ratio, not a rework rate, because one claim can be resubmitted more than once. Appeals are rare by comparison: 262,982 internal appeals against 99.6M denied claims (in- and out-of-network), 0.26%.

Every answer must end in one number a reader can repeat. Rankings describe denial patterns, not plan quality. CMS states that denial counts don't necessarily indicate issuer strength or plan quality.

**Unit of the headline: denial reasons, not denials.** Insurers can record more than one reason per denied claim, so reason counts exceed denied claims (87.2M reasons vs. 65.6M denied in-network claims in the Ind QHP tab). Shares are computed over the sum of reasons, and the headline reads "X% of denial reasons," never "X% of denials." KFF uses the same unit.

**Definition of "provider-side preventable" (my definition, not CMS's):** administrative and prior authorization / referral denials. Billing teams prevent these upstream through correct registration, clean claim submission, timely filing, and prior auth tracking. Benefit limits, exclusions, and medical necessity are plan-design or clinical issues a provider can't fix. The CMS dictionary confirms that the referral column includes prior authorization.

- **"Provider-side," not "front-office":** administrative denials include billing-office causes (duplicates, untimely filing), so "front-office" would mislabel about a quarter of all reasons. Administrative also includes coordination of benefits and workers' comp / auto liability, which a provider can't fully prevent; CMS doesn't split these out, so the limitations section says so.
- **"Member not covered" is reported separately, not in the headline.** Eligibility verification prevents some of it, but Marketplace enrollees with premium subsidies have a 3-month grace period: insurers can hold claims in months 2 and 3 and deny them if coverage ends retroactively. A front desk can verify active coverage on the date of service and still receive this denial. The data can't separate the two causes.

**Headline paragraph (final, Oct 16):**

> In 2024, 34% of the reasons HealthCare.gov insurers gave for denying in-network claims were problems a provider's billing process can prevent: administrative errors and missing prior authorizations. Among reasons with a known cause, that's more than half. We count reasons rather than claims because one denied claim can carry several reasons, and insurers report the two totals separately. Another 36% were labeled "other," so public data can't say why. For a billing manager, the place to start is administrative denials, the largest known cause at 25% of all reasons.

"More than half" is 53.31%: 34.24% ÷ 64.23% (all reasons minus "other"). Eligibility denials (7.29%, partly preventable) are reported in the case study, not the headline.

**M1 headline numbers (Ind QHP, out-of-network reason excluded, 78.6M reasons):**

| Bucket | Share of reasons |
| --- | --- |
| Other (unexplained) | 35.77% |
| **Provider-side preventable: administrative + prior auth / referral (headline)** | **34.24%** |
| Eligibility (member not covered), reported separately | 7.29% |

## Data sources

v1 uses one source: CMS's Transparency in Coverage file for the latest plan year. KFF's published analysis is used only as a benchmark. California's independent review data moves to v2, because it can't be joined to the CMS file (CMS covers HealthCare.gov states only, which excludes California, and the California data has no plan field) and would double the dashboard work.

| Dataset | Grain | Contributes | Access | Role |
| --- | --- | --- | --- | --- |
| [Transparency in Coverage PUF](https://www.cms.gov/marketplace/resources/data/public-use-files) (CMS) | One row per plan; issuer × state values repeated on each plan row | Claims received and denied, plan-level denial reasons, issuer-level appeals and resubmissions | Annual download; the PY2026 file holds PY2024 data | v1 core: Q1, Q2, Q4 |
| [KFF Marketplace denial analysis](https://www.kff.org/patient-consumer-protections/claims-denials-and-appeals-in-aca-marketplace-plans-in-2024/) | Published figures | A benchmark to reconcile against | Report and working file | v1 validation only |
| [Plan Attributes PUF](https://www.cms.gov/marketplace/resources/data/public-use-files) (CMS) | Plan per plan year | Plan type and metal level, joined on plan ID | Same page | v2: Q7 |
| [Independent Medical Review decisions](https://www.lab.data.ca.gov/dataset/independent-medical-review-imr-determinations-trend/a0930e56-7aef-46bf-9744-bbf465ad6f74) (California DMHC) | One case | Treatment category, review type, upheld or overturned | CSV download or API; all decisions since 2001 | v2: Q5, Q6 |

KFF already publishes yearly analysis of the CMS file, so this project can't just restate it. The difference is the angle. KFF reports denial reasons from a consumer-policy view, while this project asks how much is preventable from the provider side and ends in recommendations. Reconciling to KFF's published figures for the same year proves my numbers are right.

**Considered and not used now:**

- **Medicare Advantage reconsideration data:** contract-level and scattered across reports; revisit after v1.
- **Synthetic claims (Synthea, CMS synthetic files, DE-SynPUF):** claim-level but not real; a simulated remittance layer belongs to the later revenue cycle pivot.
- **Small free "revenue cycle" practice datasets:** around 1,000 synthetic rows; too small and too common.

## Data profile (M1, PY2026 file)

**Documentation:** the PY2026 dataset page has no data dictionary. The [PY24 dictionary](https://www.cms.gov/files/document/transparency-coverage-puf-datadictionary-py24.pdf) defines every column in this file and is used as the reference. The PY26 data disclaimer says nothing about suppression or legend codes.

**File structure**

- Four tabs: a disclaimer, Ind QHP, Ind SADP (stand-alone dental), and SHOP (small group). v1 uses **Ind QHP only**, matching KFF.
- Header is on row 3, under a title row and a legend row.
- Ind QHP has 4,159 plan rows across 185 issuer × state groups.
- Issuer columns (`Issuer_*`) repeat identically on every plan row in an issuer × state group. There is no separate issuer table; summing issuer columns across plan rows multiplies them by the number of plans.

**Legend codes in numeric columns**

| Code | Meaning | Found in Ind QHP |
| --- | --- | --- |
| `**` | Suppressed for small cell size | 2,648 of the 9 in-network reason cells in plans with a reported total (3,016 counting the out-of-network reason); 18 plan totals |
| `N/A` | Plan or issuer new to the Exchange | 1,600 plans (2026 plan IDs with no 2024 history) |
| `*`, `***` | Not available / not required | None in the plan-level reason columns of in-scope plans |

**Suppression threshold:** not documented for this file. The data shows it empirically: 7,853 cells report 0, the smallest positive value anywhere in the tab is 11, and no cell holds 1–10. Suppression therefore covers 1–10, consistent with CMS's general cell-size policy. At most 10 per cell × 2,648 in-network reason cells = 26,480 hidden reasons, 0.03% of 78.6M.

**Denial reason columns (10)**

Referral required (includes prior authorization), out of network, services excluded, not medically necessary (excluding behavioral health), not medically necessary (behavioral health only), benefit limit reached, member not covered, investigational/experimental/cosmetic, administrative, other. CMS's typos ("Enrolle," "Proceduce") are in the column names.

The out-of-network reason applies to closed-network plans denying claims from out-of-network providers. It is not an in-network denial, so it is excluded from the reason shares, matching KFF.

**Reconciliation to KFF**

KFF publishes rounded figures, so the tolerance is half of KFF's rounding unit: a figure KFF rounds to the nearest million passes if mine is within 0.5M; a percentage rounded to the whole number passes within 0.5 points. Anything tighter would fail on rounding alone; anything looser would be an arbitrary number I picked.

| Measure | Mine | KFF | Gap | Tolerance | Pass |
| --- | --- | --- | --- | --- | --- |
| Reporting insurers (issuer × state, 1,000+ claims) | 157 | 157 | 0 | exact | ✓ |
| In-network claims received, issuer level | 451.25M | 451M | 0.25M | 0.5M | ✓ |
| Denied in-network claims, issuer level | 84.50M | about 85M | 0.50M | 0.5M | ✓ (at the edge) |
| Overall in-network denial rate | 18.73% | 19% | 0.27 pts | 0.5 pts | ✓ |
| Denied in-network claims, plan level | 65.58M | about 66M | 0.42M | 0.5M | ✓ |
| Denial reasons, excluding out-of-network | 78.61M | about 79M | 0.39M | 0.5M | ✓ |
| Out-of-network claims received | 44.40M | 44M | 0.40M | 0.5M | ✓ |
| Out-of-network denial rate | 37.10% | 37% | 0.10 pts | 0.5 pts | ✓ |
| Reason shares: other / administrative / excluded / prior auth / medical necessity | 35.77 / 24.95 / 12.89 / 9.29 / 5.05% | 36 / 25 / 13 / 9 / 5% | ≤ 0.29 pts | 0.5 pts | ✓ |

The 1,000-claim minimum changes nothing material: it removes 2 issuer × state groups with 302 claims received between them. The PY2026 file already excludes Illinois and Georgia.

**Q4 reconciliation (Oct 21):** internal appeals filed match KFF exactly (262,982; tested). The upheld *share* matches: among the 135 issuers reporting both appeals filed and overturned, 66.4% of internal appeals were upheld vs. KFF's 66%. The upheld *count* does not: 169,566 vs. KFF's 165,863, a 3,703 gap KFF's methodology doesn't explain. Report the percentage, not the count.

**Q4 numbers (built in dbt Oct 21, `analyses/q4_after_denial.sql`):** 38.0 in-network resubmissions per 100 in-network denials (157 issuers); 0.26 internal appeals per 100 denials (147 issuers); 33.6% of internal appeals overturned (135 issuers). Each ratio uses only issuers that report both of its numbers.

**M1 checks**

- ☑ "Other" share: 35.77% of reasons. The headline survives; "other" is reported as its own bucket.
- ☑ KFF methodology: Ind QHP only; dental and SHOP excluded; out-of-network reason excluded; denials reflect final adjudication.
- ☑ Denominator: sum of reasons (excluding out-of-network). Reasons exceed reported denied claims in 989 of 1,004 fully reported plans, so denied claims can't be the denominator.
- ☑ Issuer-level rows carry in-network claims received and denied, so Q1 comes from issuer staging.
- ☑ Row counts, tab names, and exact column names.
- ☑ Null and code rates for the reason columns.
- ☑ Suppression threshold: 1–10, inferred from the data.
- ☑ Rows where denied > received: none in-network at either level. Out-of-network: 2 issuers (73836 AK, 37160 ND) and 30 plans across 6 issuers report more denials than claims received. Out-of-network counts are outside the v1 analysis; the dbt test warns on them instead of failing.
- ☑ Reconciliation tolerance: half of KFF's rounding unit. All nine checks pass; the 1,000-claim minimum removes 302 claims.

## Deliverable structure

The case study and README follow one story, in this order:

1. **Business question:** where do Marketplace denials concentrate, and how much is provider-preventable?
2. **Headline:** the preventable share of denial reasons, as one exact number.
3. **Nuance:** the "other" share that public data can't explain.
4. **Variation:** the within-state spread from Q1.
5. **Downstream work:** resubmissions and appeals from Q4.
6. **Recommendations:** three upstream actions for a billing operation.
7. **Trust:** how the number was built and validated.
8. **Limitations:** what this data can't measure, and what data would.

**Three tiers of claims, labeled everywhere.** Every number in the README, case study, and memo carries a tag, defined once at the top:

| Tag | Meaning | Examples |
| --- | --- | --- |
| *(CMS data)* | Computed directly from the file | Reason shares, 18.73% denial rate, 38.0% resubmission ratio |
| *(my classification)* | CMS data grouped by my definition | 34.24% provider-side preventable |
| *(illustrative)* | Not from the data | CARC crosswalk, proposed KPIs |

Measured results sit in the body. Illustrative material sits only in shaded callout boxes with "Illustrative" in the heading, and the CARC table appears only in the appendix. The Tableau view shows measured data only, with the preventable grouping defined in its caption.

**Recommendations format (memo).** Each of the three recommendations is one row:

| Finding | Operational interpretation | Action | Owner | Proposed KPI (not measured in this data) |
| --- | --- | --- | --- | --- |
| e.g., prior auth / referral = 9.29% of reasons | Missing authorizations create avoidable denials and rework | Confirm authorization status before the date of service | Scheduling / prior auth team | % of scheduled services with authorization verified before DOS |

The KPIs are what the manager would track going forward. They are not computed from this data, and the column header says so.

**"Why this number is trustworthy" (README panel).** Grain (plan × reason); issuer data deduplicated to issuer × state; suppressed values (1–10) treated as missing; out-of-network reason excluded; denominator is the sum of reasons; reconciles to KFF; 6 dbt tests.

**"What this data can't measure" (README and case study).** The file reports final adjudication outcomes aggregated to plan and issuer level, not claim-level remittance events. It can't measure initial denial rate, clean claim rate, days in A/R, CPT/ICD-10 patterns, or denial dollars. Those need claim- and remittance-level data and are outside v1.

**CARC appendix (case study only).** A table mapping each CMS category to the CARC codes a billing team would see on a remittance, headed: "Illustrative mapping only. CARC codes are not in the CMS dataset." Each code is checked against the X12 CARC list before publishing.

**Reproduce (README).** Pinned requirements and three commands: ingest, `dbt build`, export. No container in v1.

## Architecture and stack

The stack is local and free: Python pulls raw files, DuckDB stores them, dbt-core models and tests them, and Tableau Public presents the result. Everything lives in one GitHub repo.

- **Ingest (Python):** one script downloads the source file into data/raw/ unchanged, named by source and plan year. Raw files are never edited by hand.
- **Load (DuckDB):** dbt reads the raw xlsx directly as a dbt source (`read_xlsx` via the dbt-duckdb `external_location` config), so there is no separate load step. Every column loads as text (`all_varchar`) so legend codes can't break the load; typing happens in staging. Staging models are materialized as tables, so the database file never depends on the xlsx path after a build.
- **Transform and test (dbt-core + dbt-duckdb):** staging, intermediate, and mart models in SQL, with tests and generated docs.
- **Export:** mart tables export to CSV, since Tableau Public can't connect to DuckDB.
- **Present (Tableau Public):** one view that illustrates the headline. It supports the finding rather than being the product.
- **Document (GitHub):** a README that leads with the headline finding and the memo, readable in 60 seconds, plus a case study covering decisions, caveats, and the KFF reconciliation.

The data is small. The stack is there so every number is reproducible and tested, not because of volume, and the case study says so plainly.

## Data model

v1 has six models across three layers, built only as far as Q1, Q2, and Q4 need. Each model's grain is written down before its SQL.

| Layer | Model | Grain (one row per) | Purpose |
| --- | --- | --- | --- |
| Staging | stg_tcpuf__issuer_claims | Issuer (= issuer × state; HIOS issuer IDs are state-specific) | `select distinct` collapses the repeated issuer columns to 185 rows; types claims, denials, resubmissions, appeals; `denial_total_status` records reported (158) / suppressed (1) / new_issuer (26); percent columns dropped |
| Staging | stg_tcpuf__plan_denials | Plan | Ind QHP only; all 4,159 plans kept; `try_cast` plan-level counts so `**` and `N/A` become null; `denial_total_status` records reported / suppressed / new_plan. Downstream models filter to `reported` (2,541 plans) |
| Seed | denial_reason_buckets | Reason | My classification of the 9 reasons into 4 buckets, as a version-controlled CSV |
| Intermediate | int_plan_denials__by_reason | Plan × reason | Reported plans only; unpivot the 9 in-network reason columns into rows (22,869 = 2,541 × 9); suppressed cells kept as rows flagged `is_suppressed`; bucket joined from the seed |
| Mart | fct_plan_denials | Plan × reason | Answers Q2 |
| Mart | fct_issuer_denial_rates | Issuer (158 with a reported total) | Answers Q1. Issuer rate, 1,000-claim flag, qualifying issuers per state, state rate (ratio of sums via window functions), and `is_in_q1_comparison` |
| Mart | fct_issuer_appeals | Issuer (158 with a reported total) | Answers Q4. Counts only, plus `has_*` flags marking which ratios each issuer can join |

**Grain rules:**

- Never compute a denial rate from fct_plan_denials. Each plan's claims received repeats on every reason row, so summing it inflates the denominator by the number of reasons (9x).
- Never sum issuer columns from the raw plan rows. stg_tcpuf__issuer_claims collapses them to one row per issuer × state first.

**Tests (6 core for v1, plus not_null and accepted_values checks on staging keys and status columns):**

- unique on plan ID in stg_tcpuf__plan_denials
- unique on issuer ID in stg_tcpuf__issuer_claims (issuer IDs are state-specific: 185 IDs = 185 issuer × state pairs)
- relationships: every plan's issuer_id exists in stg_tcpuf__issuer_claims
- accepted_values on reason in int_plan_denials__by_reason (the 9 in-network reasons)
- Custom generic test `not_greater_than`: claims denied ≤ claims received, in-network (error) and out-of-network (warn, known issue), on both staging models; also internal appeals overturned ≤ filed
- Reconciliation: total reasons (excluding out-of-network) within 0.5M of KFF's 79M (built Oct 8 as a singular test: 78,605,719 passes)
- Reconciliation: overall in-network denial rate within 0.5 points of KFF's 19% (built Oct 16: 18.73% passes)

An earlier draft had a test that reason counts ≤ total denials. It is dropped: reasons legitimately exceed denials because one claim can carry several reasons.

**Deferred to v2 (the analytics engineering extension):** stg_imr__determinations and the California track, multi-year harmonization (int_tcpuf__years_unioned), stg_plan_attributes, dim_issuer, a fuller test suite, a Dockerized pipeline (one command rebuilds everything), and, separately, an optional Streamlit explorer. Kubernetes and a custom web app are out of scope.

## Milestones

The headline number lands by Oct 25. M4 through M7 are weekend-sized and finish by mid-December.

- ☑ **M1 — Explore** (due Oct 11, 2026). Done Oct 6: profile and reconciliation above.
- ☑ **M2 — Set up** (due Oct 18, 2026). Done Oct 8: environment, dbt project, source, both staging models, 7 tests passing (`dbt build`: PASS=9).
- ☑ **M3 — First finding** (due Oct 25, 2026). Done Oct 16: Q2 produced and tested in dbt (34.24% provider-side preventable, 35.77% unexplained, 22.70% not preventable, 7.29% eligibility); headline paragraph above.
- ☐ **M4 — Finish the model** (due Nov 15, 2026). Oct 16: all 6 core tests passing. Oct 21: fct_issuer_denial_rates and fct_issuer_appeals built (`dbt build`: PASS=35, WARN=2). Remaining: fct_plan_denials and the ingest script. Deliverable: dbt build runs clean from a fresh clone.
- ☐ **M5 — Analyze** (due Nov 29, 2026). Answer Q1 with the minimum-volume rule and within-state gap, then Q4 (resubmission ratio first, appeals second) if time allows. Deliverable: one headline number per question.
- ☐ **M6 — Present** (due Dec 6, 2026). One Tableau Public view that makes the headline visible: in-network denial reasons by bucket. Time-boxed to one weekend. Deliverable: published link and a static image for the README.
- ☐ **M7 — Recommend and write up** (due Dec 13, 2026). A one-page findings memo for a hypothetical clinic billing manager with 3 recommendations in the finding → action → owner → KPI format; the README (finding and memo first, trust panel, limitations box, chart, dashboard link, reproduce steps); and the case study with the CARC appendix. Generate the dbt docs and link them, without polishing them. Deliverable: a reader can repeat the headline finding after a 60-second skim.

If later steps run long, keep M3 as the hard target and push the later dates, not M3.

## Working rules

- **Docs first.** For a new concept, read the official dbt or DuckDB page before anything else.
- **One concept per session.** Each session targets one new idea (a CTE pattern, a test type, an unpivot) so it sticks.
- **Decision log.** Every non-obvious choice gets one entry in docs/decisions.md: what, why, and the alternative. This becomes the case study.
- **Interview check.** Before closing a milestone, I explain every model in it, line by line, out loud and without notes.

## Risks and decisions

Scope is fixed at one dataset, one plan year, and three questions.

| Risk | Mitigation |
| --- | --- |
| "Other" is 35.77% of reasons, so the preventable share is a floor | Report "other" as its own bucket; "a third of denial reasons are unexplained in public data" is itself a finding |
| Headline misread as "% of denials" | Always say "% of denial reasons"; explain multi-reason counting in one sentence in the README |
| "Preventable" is challenged as my own label | Definition, the dictionary's prior-auth wording, and the bucket for each column logged in decisions.md |
| Reconciliation fails | All nine checks pass at KFF's rounding precision; the issuer-level denied count sits exactly at the edge, so any filter change must rerun the test |
| Findings read as "worst insurers" | Frame as denial patterns; report Q1 as a distribution with a 1,000-claim minimum, never named extremes; quote CMS's statement that denial counts don't indicate plan quality |
| Appeals read as a provider action | State that appeals are filed by enrollees; lead Q4 with the provider-side resubmission ratio |
| Recommendations overclaim what the data measures | Three-tier labels on every number; KPIs labeled as proposed; limitations box names what the data can't measure |
| Project duplicates KFF | Lead with the provider-side preventable angle and the recommendations; the reconciliation shows the numbers are right |
| Schedule slips | Headline number done by Oct 25; later milestones are weekend-sized |
| Fan-out inflates totals (plan × reason rows; issuer values repeated on plan rows) | Grain rules above; uniqueness tests on both staging models |
| Scope creep | California, multiple years, Plan Attributes, Medicare Advantage, and synthetic remittance data stay in v2 |

**Decisions made:**

- Oct 3: Analyst-first framing; the fuller analytics engineering build is v2.
- Oct 3: National HealthCare.gov view for the headline; Q1 covers within-state spread.
- Oct 3: One plan year only; the trend question (Q3) moves to v2.
- Oct 3: California independent review track moves to v2.
- Oct 3: Q1 is answered at issuer × state grain, not from fct_plan_denials.
- Oct 5: Ind QHP tab only; dental and SHOP excluded, matching KFF.
- Oct 5: Shares are computed over the sum of reasons, excluding the out-of-network reason; the headline unit is "denial reasons."
- Oct 5: Suppressed cells (`**`) are treated as missing and all plans with a reported total are kept, rather than dropping the 1,537 plans with any suppressed reason (35.34% of denied claims).
- Oct 5: Q1 uses issuer-level columns, deduplicated to issuer × state.
- Oct 5: Q1 applies KFF's 1,000-claim minimum and reports within-state gaps as a distribution.
- Oct 5: Q4 adds the resubmission-to-denial ratio as its provider-side number.
- Oct 5: Docker and an interactive app move to v2; v1 reproducibility is pinned requirements plus three commands.
- Oct 6: The bucket is "provider-side preventable," not "front-office."
- Oct 6: Member-not-covered is reported separately (7.29%), not in the headline.
- Oct 6: Every number is tagged CMS data, my classification, or illustrative.
- Oct 6: Reconciliation tolerance is half of KFF's rounding unit.
- Oct 7: Staging keeps every row and flags status; filtering happens downstream.
- Oct 7: Staging models are materialized as tables, not views.
- Oct 8: The issuer model's key is issuer_id alone; HIOS IDs are state-specific.
- Oct 8: The issuer model collapses rows with `select distinct` and relies on the unique test to catch conflicts, rather than `group by` with an aggregate.
- Oct 8: The reason-to-bucket classification lives in a dbt seed, not a CASE statement.
- Oct 8: Suppressed reason cells stay in the intermediate model as flagged rows.
- Oct 16: The headline leads with 34% of all reasons; "more than half of reasons with a known cause" is the supporting line.
- Oct 16: Out-of-network denied > received is a warning, not a failure.
- Oct 21: Q1 compares issuers with 1,000+ in-network claims in states with 2+ such issuers.
- Oct 21: The Q1 mart stores each issuer's own rate alongside its counts; rollups always re-sum the counts.
- Oct 21: Q4 ratios use matched sets: an issuer counts only if both the numerator and denominator are reported.
- Oct 21: The appeal rate divides by all denials (in- and out-of-network), since appeals aren't split by network.

## Sources

- [CMS Health Insurance Exchange Public Use Files](https://www.cms.gov/marketplace/resources/data/public-use-files)
- [CMS Transparency in Coverage data dictionary, PY22](https://www.cms.gov/files/document/transparency-in-coverage-datadictionary-py22.pdf)
- [CMS Transparency in Coverage data dictionary, PY24](https://www.cms.gov/files/document/transparency-coverage-puf-datadictionary-py24.pdf)
- [CMS Transparency PUF data disclaimer, PY26](https://www.cms.gov/files/document/transparency-coverage-datadisclaimer-py26.pdf-0)
- [CMS cell size suppression policy (via ResDAC)](https://resdac.org/node/1506)
- [KFF: Claims denials and appeals in ACA Marketplace plans, 2024](https://www.kff.org/patient-consumer-protections/claims-denials-and-appeals-in-aca-marketplace-plans-in-2024/)
- [KFF news release on 2023 denials](https://www.kff.org/affordable-care-act/press-release/healthcare-gov-insurers-denied-nearly-1-in-5-in-network-claims-in-2023-but-information-about-reasons-is-limited-in-public-data/)
- [California DMHC Independent Medical Review dataset](https://www.lab.data.ca.gov/dataset/independent-medical-review-imr-determinations-trend/a0930e56-7aef-46bf-9744-bbf465ad6f74) (v2)
- [Independent Medical Review field list](https://baselight.app/u/kaggle/dataset/prasad22_ca_independent_medical_review) (v2)
