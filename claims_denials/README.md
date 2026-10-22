# Claims Denial Analysis

**Headline finding:** In 2024, 34% of the reasons HealthCare.gov insurers gave for denying in-network claims were problems a provider's billing process can prevent: administrative errors and missing prior authorizations. Among reasons with a known cause, that's more than half. We count reasons rather than claims because one denied claim can carry several reasons, and insurers report the two totals separately. Another 36% were labeled "other," so public data can't say why. For a billing manager, the place to start is administrative denials, the largest known cause at 25% of all reasons.

Data: [CMS Transparency in Coverage PUF, PY2026](https://catalog.data.gov/dataset/transparency-in-coverage-puf-py2026) (plan year 2024 claims). Totals reconcile to [KFF's analysis](https://www.kff.org/patient-consumer-protections/claims-denials-and-appeals-in-aca-marketplace-plans-in-2024/) of the same file.

- [Project plan](docs/project_plan.md)
- [Decision log](docs/decisions.md)

## Reproduce

Requires Python 3.10 or newer. From a fresh clone of this repository:

```
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python scripts/ingest.py
cd claims_denials
dbt build
```

`ingest.py` downloads the raw CMS file into `data/raw/` and checks its fingerprint against the version this analysis was built on. `dbt build` creates every model and runs every test, including the reconciliations against KFF. Two out-of-network data-quality warnings are expected; see the decision log.
