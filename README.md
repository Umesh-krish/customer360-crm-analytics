# Customer 360 — CRM Analytics Engine

End-to-end CRM analytics on the Olist Brazilian E-Commerce dataset (100k+ real orders):
Python data cleaning, SQL models (RFM segmentation, churn, CLV, cohorts), a Tableau dashboard,
and campaign-ready segments pushed into HubSpot.

**Live dashboard:** https://public.tableau.com/app/profile/umesh.krishnan/viz/Customer360CRMAnalyticsOlistE-Commerce/Dashboard1

## Key insights

1. **EUR 5.4M win-back opportunity** — 23,013 lapsed high-value customers (~25% of the base) hold EUR 5.4M in proven historic spend: the top-priority segment for win-back campaigns.
2. **Even Champions leak** — ~18% of top-scoring customers have gone 180+ days quiet. Retention risk starts before customers look "at risk", so recency deserves early-warning monitoring.
3. **Value = basket size, not loyalty (in this dataset)** — top customers spend 15-90x the average and almost all bought exactly once. The right strategy is converting high-basket first purchases into second orders, not frequency rewards.
4. **Method honesty** — quartile-based RFM forces equal segment sizes, and the churn flag shares the recency signal with segmentation. In production, cutoffs would be derived from repurchase curves.

## Pipeline

```
Kaggle CSVs -> Python cleaning (pandas) -> SQLite -> SQL models -> CSV exports -> Tableau + HubSpot
```

## What's in this repo

| File | Purpose |
|---|---|
| `02_load_and_clean.py` | Cleans the 9 Olist CSVs and builds `customer360.db` (SQLite) |
| `03_analysis_queries.sql` | The models: revenue per order, customer summary, RFM (CTEs + NTILE window functions + CASE), churn by segment, CLV ranking, cohort retention |
| `04_export_models.py` | Exports model outputs for Tableau and a HubSpot contact import file |

## How to run

1. Download the [Olist dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) from Kaggle and place the CSVs in `data/raw/`
2. `python 02_load_and_clean.py` — builds the SQLite database
3. Run `03_analysis_queries.sql` section by section (DB Browser for SQLite works well); sections 2 and 3 create the `customer_summary` and `rfm` tables
4. `python 04_export_models.py` — exports CSVs to `data/outputs/`
5. Build the dashboard from `rfm_segments.csv` / import `hubspot_contacts.csv` into HubSpot and create an active list per segment

## CRM activation (HubSpot)

The RFM segments were imported into a HubSpot portal as contacts with custom properties
(RFM Segment, Lifetime Value, Recency Days), turned into an auto-updating active list
("At Risk - High Value — win-back audience"), and targeted with a re-engagement email —
closing the loop from raw data to campaign.

## Notes on the data

- Olist quirk: `customer_id` regenerates per order; the real person is `customer_unique_id`. All customer-level aggregation uses the latter.
- Only delivered orders are counted toward revenue.

---

*Umesh Krishnan Gopalakrishnan — MSc Data Analytics (DCU) | [Tableau Public](https://public.tableau.com/app/profile/umesh.krishnan)*
