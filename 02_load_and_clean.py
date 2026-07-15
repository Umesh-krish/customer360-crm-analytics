"""
02_load_and_clean.py
Loads the Olist CSVs, cleans them, and builds customer360.db (SQLite).
Put the Kaggle CSVs in data/raw/ first, then run:  python 02_load_and_clean.py
"""

import pandas as pd
import sqlite3
from pathlib import Path

RAW = Path("data/raw")
DB = "customer360.db"

# --- Load ---
customers = pd.read_csv(RAW / "olist_customers_dataset.csv")
orders = pd.read_csv(RAW / "olist_orders_dataset.csv")
items = pd.read_csv(RAW / "olist_order_items_dataset.csv")
payments = pd.read_csv(RAW / "olist_order_payments_dataset.csv")
reviews = pd.read_csv(RAW / "olist_order_reviews_dataset.csv")

# --- Clean: orders ---
date_cols = [c for c in orders.columns if "timestamp" in c or "date" in c]
for c in date_cols:
    orders[c] = pd.to_datetime(orders[c], errors="coerce")

# Keep only delivered orders for revenue analysis (document this decision!)
orders = orders[orders["order_status"] == "delivered"].copy()
orders = orders.dropna(subset=["order_purchase_timestamp"])

# --- Clean: items ---
items["price"] = pd.to_numeric(items["price"], errors="coerce")
items["freight_value"] = pd.to_numeric(items["freight_value"], errors="coerce")
items = items.dropna(subset=["price"])

# --- Clean: customers ---
# Olist quirk: customer_unique_id is the real person; customer_id changes per order
customers = customers.drop_duplicates(subset=["customer_id"])

# --- Clean: reviews ---
reviews = reviews.drop_duplicates(subset=["review_id"])
reviews["review_score"] = pd.to_numeric(reviews["review_score"], errors="coerce")

# --- Write to SQLite ---
con = sqlite3.connect(DB)
customers.to_sql("customers", con, if_exists="replace", index=False)
orders.to_sql("orders", con, if_exists="replace", index=False)
items.to_sql("order_items", con, if_exists="replace", index=False)
payments.to_sql("payments", con, if_exists="replace", index=False)
reviews.to_sql("reviews", con, if_exists="replace", index=False)

# Helpful indexes
cur = con.cursor()
cur.execute("CREATE INDEX IF NOT EXISTS idx_orders_cust ON orders(customer_id);")
cur.execute("CREATE INDEX IF NOT EXISTS idx_items_order ON order_items(order_id);")
con.commit()
con.close()

print("Done. customer360.db created with tables: customers, orders, order_items, payments, reviews")
