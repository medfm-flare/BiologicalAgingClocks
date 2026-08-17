"""
Preprocessing script for interventions volcano plot data.
Processes CSV data, output data, and parsed reports.
"""

from pathlib import Path

import numpy as np
import pandas as pd


def normalize_scores(scores):
    """Normalize scores for visualization (0-1 range), handling NaN values."""
    if len(scores) == 0:
        return scores

    scores = np.array(scores, dtype=float)

    # Create mask for valid (non-NaN) scores
    valid_mask = ~np.isnan(scores)
    valid_scores = scores[valid_mask]

    if len(valid_scores) == 0:
        # All NaN - return array of 0.5
        return np.full_like(scores, 0.5, dtype=float)

    min_score = valid_scores.min()
    max_score = valid_scores.max()

    if max_score == min_score:
        return np.ones_like(scores, dtype=float) * 0.5

    # Normalize, preserving NaN values
    normalized = (scores - min_score) / (max_score - min_score)
    normalized[~valid_mask] = 0.5  # Replace NaN with 0.5

    return normalized


def check_report_availability(case_id, base_dir):
    """
    Check if output data and report exist for a case ID.

    Args:
        case_id: Case identifier with suffix (e.g., 'GSE122080-9737')
        base_dir: Path to interventions data directory

    Returns:
        tuple: (has_output, has_report)
    """
    # The case_id from CSV already includes the suffix (e.g., 'GSE146176-3329')
    # Check for output directory with identified_relevance.json
    output_path = base_dir / "output" / case_id / "identified_relevance.json"
    has_output = output_path.exists()
    
    # Check for report directory with parsed_report.html
    report_path = base_dir / "report" / case_id / "parsed_report.html"
    has_report = report_path.exists()
    
    return has_output, has_report


def preprocess_volcano_data(csv_path, base_dir, data_output_dir):
    """
    Process the main CSV file for volcano plot.

    Args:
        csv_path: Path to detailed_scores_result_mm_rna.csv
        base_dir: Base directory with output/ and report/ subdirectories
        data_output_dir: Directory to save processed data
    """
    print("Loading CSV data...")
    df = pd.read_csv(csv_path)

    print(f"Loaded {len(df)} records")

    # Calculate -log10(FDR) for y-axis
    df["neg_log10_fdr"] = -np.log10(df["fdr"].replace(0, 1e-300))

    # Handle inf values
    df["neg_log10_fdr"] = df["neg_log10_fdr"].replace(
        [np.inf, -np.inf], df["neg_log10_fdr"].replace([np.inf, -np.inf], np.nan).max()
    )

    # Use final_ranking_score as final_score
    if "final_ranking_score" in df.columns:
        df["final_score"] = df["final_ranking_score"].fillna(50)
    elif "trust_score" in df.columns:
        df["final_score"] = df["trust_score"].fillna(50)
    else:
        df["final_score"] = 50

    # Normalize scores for marker size (0-1)
    df["normalized_score"] = normalize_scores(df["final_score"].values)

    # Calculate marker size (cubic scale for better distinction)
    df["marker_size"] = df["normalized_score"] ** 3 * 120

    # Calculate marker opacity
    df["marker_opacity"] = 0.3 + df["normalized_score"] * 0.7

    # Check for report availability for each case_id (full ID with suffix)
    print("Checking report availability...")
    
    # Use case_id which has the full identifier (e.g., 'GSE146176-3329')
    # gse_id only has the base (e.g., 'GSE146176')
    if "case_id" not in df.columns:
        print("ERROR: case_id column not found in CSV!")
        unique_ids = df["gse_id"].dropna().unique()
    else:
        unique_ids = df["case_id"].dropna().unique()
    
    print(f"Total unique case IDs: {len(unique_ids)}")
    print(f"Sample case IDs from CSV: {list(unique_ids[:5])}")

    output_available = set()
    reports_available = set()

    for case_id in unique_ids:
        has_output, has_report = check_report_availability(case_id, base_dir)
        if has_output:
            output_available.add(case_id)
        if has_report:
            reports_available.add(case_id)

    print(f"Found {len(output_available)} case IDs with output data")
    print(f"Found {len(reports_available)} case IDs with parsed reports")

    # Mark availability in dataframe using case_id
    df["has_output_data"] = df["case_id"].isin(output_available)
    df["has_report"] = df["case_id"].isin(reports_available)

    # Clean up condition_category
    df["condition_category"] = df["condition_category"].fillna("Other")

    # Save to parquet for fast loading
    output_path = data_output_dir / "volcano_data.parquet"
    df.to_parquet(output_path, index=False)
    print(f"Saved volcano data to {output_path}")

    # Also save as CSV for debugging
    csv_output = data_output_dir / "volcano_data.csv"
    df.to_csv(csv_output, index=False)
    print(f"Saved volcano data CSV to {csv_output}")

    return df


def main():
    """Main preprocessing pipeline."""
    # Paths
    base_dir = Path(__file__).parent / "data" / "interventions"
    csv_path = base_dir / "detailed_scores_result_mm_rna.csv"
    data_output_dir = base_dir

    print("=" * 60)
    print("Interventions Data Preprocessing")
    print("=" * 60)

    # Check if output and report directories exist
    output_dir = base_dir / "output"
    report_dir = base_dir / "report"

    if not output_dir.exists():
        print(f"\nWARNING: Output directory not found: {output_dir}")
    else:
        output_dirs = list(output_dir.glob("*/identified_relevance.json"))
        output_count = len(output_dirs)
        print(f"\nFound {output_count} output datasets in {output_dir}")
        if output_count > 0:
            # Show sample directory names
            sample_dirs = [p.parent.name for p in output_dirs[:5]]
            print(f"Sample output directories: {sample_dirs}")

    if not report_dir.exists():
        print(f"\nWARNING: Report directory not found: {report_dir}")
    else:
        report_files = list(report_dir.glob("*/parsed_report.html"))
        reports_count = len(report_files)
        print(f"Found {reports_count} parsed reports in {report_dir}")
        if reports_count > 0:
            # Show sample directory names
            sample_dirs = [p.parent.name for p in report_files[:5]]
            print(f"Sample report directories: {sample_dirs}")

    # Process volcano data
    print("\nProcessing volcano plot data...")
    df = preprocess_volcano_data(csv_path, base_dir, data_output_dir)

    print("\n" + "=" * 60)
    print("Preprocessing complete!")
    print(f"Volcano data: {len(df)} records")
    print(f"  - With output data: {df['has_output_data'].sum()}")
    print(f"  - With parsed reports: {df['has_report'].sum()}")
    print("=" * 60)


if __name__ == "__main__":
    main()