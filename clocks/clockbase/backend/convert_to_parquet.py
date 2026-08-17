import os
from pathlib import Path
import pandas as pd

BASE = Path(__file__).resolve().parent / "data"
OUTPUT_META = BASE / "gse_metadata.parquet"


def convert_csv_to_parquet(csv_path: Path):
    try:
        df = pd.read_csv(csv_path)
        df.to_parquet(csv_path.with_suffix(".parquet"), index=False)
        print(f"✅ Converted {csv_path.relative_to(BASE)}")
    except Exception as e:
        print(f"❌ Failed {csv_path}: {e}")


def main():
    for subdir in ["GEO_hs_dnam", "GEO_mm_dnam", "GEO_hs_rna", "GEO_mm_rna"]:
        dir_path = BASE / subdir
        if not dir_path.exists():
            print(f"⚠️ Directory {dir_path} does not exist, skipping.")
            continue

        for file in os.listdir(dir_path):
            if file.endswith(".csv"):
                csv_path = dir_path / file
                convert_csv_to_parquet(csv_path)


if __name__ == "__main__":
    main()
