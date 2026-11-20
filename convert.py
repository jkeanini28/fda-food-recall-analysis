"""
convert.py

Converts the openFDA food enforcement JSON download into a CSV file that can be imported into SQLite.

Setup:
    1. Download the food enforcement data from https://open.fda.gov
       and unzip it into the same folder as this script.
    2. Install pandas if needed:  pip install pandas
    3. If your JSON file has a different name, change JSON_FILE below.

Run:
    python convert.py
"""

import json

import pandas as pd

JSON_FILE = "food-enforcement-0001-of-0001.json" 
CSV_FILE = "recalls.csv"

with open(JSON_FILE, encoding="utf-8") as f:
    data = json.load(f)

# json_normalize flattens any nested fields into regular columns.
df = pd.json_normalize(data["results"])

df.to_csv(CSV_FILE, index=False)

# Quick check: number of rows and columns, then the column names.
print(df.shape)
print(df.columns.tolist())
