"""
04_export_models.py
Exports the SQL model outputs to CSVs for Power BI, plus a HubSpot import file.
Run AFTER executing 03_analysis_queries.sql (sections 2 and 3 create the tables).
"""

import pandas as pd
import sqlite3
from pathlib import Path

OUT = Path("data/outputs")
OUT.mkdir(parents=True, exist_ok=True)

con = sqlite3.connect("customer360.db")

# Power BI feeds
rfm = pd.read_sql("SELECT * FROM rfm", con)
rfm.to_csv(OUT / "rfm_segments.csv", index=False)

summary = pd.read_sql("SELECT * FROM customer_summary", con)
summary.to_csv(OUT / "customer_summary.csv", index=False)

# HubSpot import file (contacts need an email — generate demo emails)
hs = rfm[["customer_unique_id", "segment", "monetary", "recency_days"]].copy()
hs["email"] = hs["customer_unique_id"].str[:12] + "@demo-customer360.com"
hs = hs.rename(columns={"monetary": "lifetime_value"})
hs.head(500).to_csv(OUT / "hubspot_contacts.csv", index=False)  # 500 is plenty for demo

con.close()
print("Exported: rfm_segments.csv, customer_summary.csv, hubspot_contacts.csv → data/outputs/")
