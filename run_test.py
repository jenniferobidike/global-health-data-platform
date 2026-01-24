import os
import pandas as pd

print("=== DEBUG START ===")
print("CWD:", os.getcwd())

print("datasets exists?", os.path.exists("datasets"), os.path.abspath("datasets"))
print("outputs exists?", os.path.exists("outputs"), os.path.abspath("outputs"))
print("outputs is dir?", os.path.isdir("outputs"))

print("\n--- datasets listing ---")
print(os.listdir("datasets"))

# Ensure outputs folder
if os.path.exists("outputs") and not os.path.isdir("outputs"):
    raise RuntimeError("'outputs' exists but is NOT a folder.")

os.makedirs("outputs", exist_ok=True)

# Load ONE file to prove reading works
path = os.path.join("datasets", "stg_life_expectancy.csv")
df = pd.read_csv(path)

print("\nLoaded stg_life_expectancy.csv")
print("Shape:", df.shape)
print("Columns:", list(df.columns))

# Write a test output file
out_path = os.path.join("outputs", "test_write.csv")
df.head(5).to_csv(out_path, index=False)

print("\nWROTE:", os.path.abspath(out_path))
print("=== DEBUG END ===")
