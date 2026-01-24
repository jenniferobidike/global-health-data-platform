import os
import pandas as pd
import matplotlib.pyplot as plt

print("=== EDA SCRIPT START ===")
print("CWD:", os.getcwd())

DATA_DIR = "datasets"
OUT_DIR = "outputs"

# Validate folders
print("DATA_DIR exists?", os.path.exists(DATA_DIR), "->", os.path.abspath(DATA_DIR))
print("OUT_DIR exists?", os.path.exists(OUT_DIR), "->", os.path.abspath(OUT_DIR))

# outputs must be a directory
if os.path.exists(OUT_DIR) and not os.path.isdir(OUT_DIR):
    raise RuntimeError(f"'{OUT_DIR}' exists but is NOT a folder. Delete it and create a folder named outputs.")

os.makedirs(OUT_DIR, exist_ok=True)

# List dataset files
print("\n--- datasets listing ---")
print(os.listdir(DATA_DIR))

def load_stg_csv(filename: str, metric_col: str) -> pd.DataFrame:
    path = os.path.join(DATA_DIR, filename)
    print("\nLoading:", os.path.abspath(path))

    if not os.path.exists(path):
        raise FileNotFoundError(f"Missing file: {path}")

    df = pd.read_csv(path)
    df.columns = [c.strip() for c in df.columns]

    # If your CSV still has Kaggle names, normalize them
    if "Location" in df.columns and "country" not in df.columns:
        df = df.rename(columns={"Location": "country"})
    if "Period" in df.columns and "year" not in df.columns:
        df = df.rename(columns={"Period": "year"})
    if "First Tooltip" in df.columns and metric_col not in df.columns:
        df = df.rename(columns={"First Tooltip": metric_col})

    # Validate expected columns
    required = ["country", "year", metric_col]
    for col in required:
        if col not in df.columns:
            raise ValueError(
                f"{filename} missing '{col}'. Columns found: {list(df.columns)}"
            )

    # Types
    df["country"] = df["country"].astype(str).str.strip()
    df["year"] = pd.to_numeric(df["year"], errors="coerce").astype("Int64")
    df[metric_col] = pd.to_numeric(df[metric_col], errors="coerce")

    # Keep key columns only
    df = df[["country", "year", metric_col]].dropna(subset=["country", "year"])
    df = df.drop_duplicates(subset=["country", "year"])

    print(f"Loaded {filename}: rows={len(df)}")
    return df

# ✅ Filenames match your `dir datasets` output exactly:
life = load_stg_csv("stg_life_expectancy.csv", "life_expectancy")
mm   = load_stg_csv("stg_maternal_mortality.csv", "maternal_mortality_ratio")
uhc  = load_stg_csv("stg_uhc_index.csv", "uhc_index")
doc  = load_stg_csv("stg_doctors.csv", "doctors_per_10000")
pha  = load_stg_csv("stg_pharmacists.csv", "pharmacists_per_10000")  # <-- singular filename
wat  = load_stg_csv("stg_water.csv", "basic_water_access_pct")
ncd  = load_stg_csv("stg_ncd_30_70.csv", "ncd_mortality_30_70")

# Merge into fact-style dataset (life expectancy as base)
fact = life.copy()
for d in [mm, uhc, doc, pha, wat, ncd]:
    fact = fact.merge(d, on=["country", "year"], how="left")

# Standardize pharmacists to per 10k for comparability
fact["pharmacists_per_10000"] = fact["pharmacists_per_10000"] * 10

# Save merged dataset
fact_path = os.path.join(OUT_DIR, "fact_global_health_local.csv")
fact.to_csv(fact_path, index=False)
print("\n✅ Saved merged dataset:", os.path.abspath(fact_path))
print("Rows:", fact.shape[0], "| Countries:", fact["country"].nunique(),
      "| Year range:", (fact["year"].min(), fact["year"].max()))

# Latest year subset
latest_year = int(fact["year"].max())
latest = fact[fact["year"] == latest_year].copy()
print("Latest year:", latest_year, "| Latest rows:", len(latest))

# Trends (global averages)
trend = fact.groupby("year", as_index=False).mean(numeric_only=True)

# Plot: Life expectancy trend
p1 = os.path.join(OUT_DIR, "trend_life_expectancy.png")
plt.figure()
plt.plot(trend["year"], trend["life_expectancy"])
plt.title("Global Average Life Expectancy Over Time")
plt.xlabel("Year")
plt.ylabel("Life expectancy")
plt.tight_layout()
plt.savefig(p1, dpi=200)
plt.close()
print("✅ Saved:", os.path.abspath(p1))

# Plot: Maternal mortality trend
p2 = os.path.join(OUT_DIR, "trend_maternal_mortality.png")
plt.figure()
plt.plot(trend["year"], trend["maternal_mortality_ratio"])
plt.title("Global Average Maternal Mortality Over Time")
plt.xlabel("Year")
plt.ylabel("Maternal mortality ratio")
plt.tight_layout()
plt.savefig(p2, dpi=200)
plt.close()
print("✅ Saved:", os.path.abspath(p2))

# Scatter: doctors vs life expectancy (latest year)
p3 = os.path.join(OUT_DIR, "scatter_doctors_life_expectancy.png")
plt.figure()
plt.scatter(latest["doctors_per_10000"], latest["life_expectancy"])
plt.title(f"Doctors vs Life Expectancy ({latest_year})")
plt.xlabel("Doctors per 10,000")
plt.ylabel("Life expectancy")
plt.tight_layout()
plt.savefig(p3, dpi=200)
plt.close()
print("✅ Saved:", os.path.abspath(p3))

# Scatter: UHC vs maternal mortality (latest year)
p4 = os.path.join(OUT_DIR, "scatter_uhc_maternal_mortality.png")
plt.figure()
plt.scatter(latest["uhc_index"], latest["maternal_mortality_ratio"])
plt.title(f"UHC Index vs Maternal Mortality ({latest_year})")
plt.xlabel("UHC index")
plt.ylabel("Maternal mortality ratio")
plt.tight_layout()
plt.savefig(p4, dpi=200)
plt.close()
print("✅ Saved:", os.path.abspath(p4))

# Correlation matrix (latest year) -> CSV
corr_cols = [
    "life_expectancy",
    "maternal_mortality_ratio",
    "uhc_index",
    "doctors_per_10000",
    "pharmacists_per_10000",
    "basic_water_access_pct",
    "ncd_mortality_30_70"
]
corr_path = os.path.join(OUT_DIR, "correlation_latest_year.csv")
latest[corr_cols].corr().to_csv(corr_path)
print("✅ Saved:", os.path.abspath(corr_path))

print("\n=== EDA SCRIPT DONE ===")
