"""
Interventions API endpoints for volcano plot and aging research reports.
"""

import json
from pathlib import Path
from typing import Any

import pandas as pd
from fastapi import APIRouter, HTTPException, Query
from loguru import logger

router = APIRouter(prefix="/interventions")

# Cache for volcano data
_volcano_data_cache: pd.DataFrame | None = None
_data_path = Path(__file__).parent.parent / "data" / "interventions"


def get_volcano_data() -> pd.DataFrame:
    """Load and cache volcano plot data."""
    global _volcano_data_cache

    if _volcano_data_cache is None:
        parquet_path = _data_path / "volcano_data.parquet"

        if not parquet_path.exists():
            logger.error(f"Volcano data not found at {parquet_path}")
            raise FileNotFoundError("Volcano data not found. Please run preprocess_interventions.py first.")

        logger.info(f"Loading volcano data from {parquet_path}")
        _volcano_data_cache = pd.read_parquet(parquet_path)
        logger.info(f"Loaded {len(_volcano_data_cache)} volcano plot records")

    return _volcano_data_cache


@router.get("/volcano-data")
async def get_volcano_plot_data(
    category: list[str] | None = Query(None, description="Filter by intervention category"),
    min_score: int | None = Query(None, ge=0, le=200, description="Minimum final score"),
    max_fdr: float | None = Query(None, ge=0, le=1, description="Maximum FDR threshold"),
    min_abs_effect: float | None = Query(None, ge=0, description="Minimum absolute log2FoldChange"),
    search: str | None = Query(None, description="Search in GSE ID, case ID, intervention, or condition name"),
    has_report: bool | None = Query(None, description="Filter by mini paper availability"),
    has_score: bool | None = Query(None, description="Filter by score availability (exclude N/A values)"),
    page: int = Query(1, ge=1, description="Page number (1-indexed)"),
    page_size: int = Query(50, ge=1, le=10000, description="Number of items per page"),
    sort_by: str = Query("trust_score", description="Column to sort by"),
    sort_order: str = Query("desc", description="Sort order: asc or desc"),
) -> dict[str, Any]:
    """
    Get volcano plot data with optional filtering and pagination.

    Parameters:
    - category: List of categories to include (Genetic, Drug, Environment, Disease, Other)
    - min_score: Minimum final score threshold
    - max_fdr: Maximum FDR value (e.g., 0.05 for significant results)
    - min_abs_effect: Minimum absolute effect size
    - search: Search query for GSE ID, case ID, intervention, or condition name
    - has_report: Filter to show only items with mini paper (True) or all items (None/False)
    - has_score: Filter to show only items with valid score (exclude N/A values)
    - page: Page number (starting from 1)
    - page_size: Number of items per page
    - sort_by: Column name to sort by
    - sort_order: Sort order (asc or desc)

    Returns:
    - data: List of data points for current page
    - metadata: Summary statistics
    - pagination: Pagination information
    """
    try:
        # Log incoming parameters
        logger.info(f"Request params - has_score: {has_score} (type: {type(has_score)})")

        df = get_volcano_data().copy()

        # Add row_id for unique identification (index-based)
        df = df.reset_index(drop=True)
        df["row_id"] = df.index

        # Apply filters
        if category is not None:
            if len(category) == 0:
                df = df[df["condition_category"].isin([])]
            else:
                df = df[df["condition_category"].isin(category)]

        if min_score is not None:
            df = df[df["trust_score"] >= min_score]

        if max_fdr is not None:
            df = df[df["fdr"] <= max_fdr]

        if min_abs_effect is not None:
            df = df[df["log2FoldChange"].abs() >= min_abs_effect]

        # Apply mini paper filter
        if has_report is True:
            df = df[df["has_report"]]

        # Apply score filter (exclude N/A values)
        if has_score is True:
            df = df[df["trust_score"] > 0]

        # Apply search filter
        if search is not None and search.strip():
            search_lower = search.strip().lower()
            logger.info(f"Applying search filter: '{search_lower}'")

            # Build search mask dynamically based on available columns
            # Use regex=False to treat search as literal string, not regex pattern
            search_mask = df["gse_id"].astype(str).str.lower().str.contains(search_lower, na=False, regex=False)

            # Also search in case_id (full identifier with suffix)
            if "case_id" in df.columns:
                search_mask = search_mask | df["case_id"].astype(str).str.lower().str.contains(
                    search_lower, na=False, regex=False
                )

            # Search in intervention name
            if "intervention" in df.columns:
                search_mask = search_mask | df["intervention"].astype(str).str.lower().str.contains(
                    search_lower, na=False, regex=False
                )

            # Search in condition name
            if "condition_name" in df.columns:
                search_mask = search_mask | df["condition_name"].astype(str).str.lower().str.contains(
                    search_lower, na=False, regex=False
                )

            # Search in comparison name
            if "comparison_name" in df.columns:
                search_mask = search_mask | df["comparison_name"].astype(str).str.lower().str.contains(
                    search_lower, na=False, regex=False
                )

            df = df[search_mask]
            logger.info(f"Search resulted in {len(df)} matches")

        # Total count after filtering
        total_count = len(df)

        # Calculate metadata
        metadata = {
            "total_comparisons": total_count,
            "significant_count": int((df["fdr"] < 0.05).sum()) if len(df) > 0 else 0,
            "categories": df["condition_category"].value_counts().to_dict() if len(df) > 0 else {},
            "score_range": {
                "min": float(df["trust_score"].min()) if len(df) > 0 else 0,
                "max": float(df["trust_score"].max()) if len(df) > 0 else 0,
            },
            "effect_range": {
                "min": float(df["log2FoldChange"].min()) if len(df) > 0 else 0,
                "max": float(df["log2FoldChange"].max()) if len(df) > 0 else 0,
            },
        }

        # Sort data
        if sort_by in df.columns:
            ascending = sort_order.lower() == "asc"
            df = df.sort_values(by=sort_by, ascending=ascending)

        # Apply pagination
        start_idx = (page - 1) * page_size
        end_idx = start_idx + page_size
        df_page = df.iloc[start_idx:end_idx]

        # Convert to records (limit to essential columns for performance)
        columns_to_return = [
            "row_id",
            "gse_id",
            "case_id",
            "comparison_name",
            "condition_name",
            "condition_category",
            "intervention",
            "log2FoldChange",
            "pvalue",
            "fdr",
            "neg_log10_fdr",
            "trust_score",
            "marker_size",
            "marker_opacity",
            "has_output_data",
            "has_report",
        ]

        # Only include columns that exist
        available_columns = [col for col in columns_to_return if col in df_page.columns]
        data_records = df_page[available_columns].to_dict("records")

        # Pagination info
        total_pages = (total_count + page_size - 1) // page_size if total_count > 0 else 0

        return {
            "data": data_records,
            "metadata": metadata,
            "pagination": {
                "page": page,
                "page_size": page_size,
                "total_items": total_count,
                "total_pages": total_pages,
                "has_next": page < total_pages,
                "has_prev": page > 1,
            },
        }

    except Exception as e:
        logger.error(f"Error fetching volcano data: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/report/{case_id}/output")
async def get_output_data(case_id: str) -> dict[str, Any]:
    """
    Get output data for a specific case ID.

    Parameters:
    - case_id: Case identifier with suffix (e.g., GSE122080-9737)

    Returns:
    - case_id: Case identifier
    - relevance: Identified relevance data
    - queries: Search queries used
    - sample: Sample information
    """
    output_dir = _data_path / "output" / case_id

    if not output_dir.exists():
        logger.warning(f"Output directory not found for {case_id}")
        raise HTTPException(
            status_code=404,
            detail=f"Output data not found for {case_id}",
        )

    try:
        result = {"case_id": case_id}

        # Load identified_relevance.json
        relevance_path = output_dir / "identified_relevance.json"
        if relevance_path.exists():
            with open(relevance_path, "r", encoding="utf-8") as f:
                result["relevance"] = json.load(f)

        # Load queries.json if exists
        queries_path = output_dir / "queries.json"
        if queries_path.exists():
            with open(queries_path, "r", encoding="utf-8") as f:
                result["queries"] = json.load(f)

        # Load sample.json if exists
        sample_path = output_dir / "sample.json"
        if sample_path.exists():
            with open(sample_path, "r", encoding="utf-8") as f:
                result["sample"] = json.load(f)

        return result

    except Exception as e:
        logger.error(f"Error loading output data for {case_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/report/{case_id}/parsed")
async def get_parsed_report(
    case_id: str, format: str = Query("html", description="Format: html or md")
) -> dict[str, Any]:
    """
    Get parsed report (mini paper) for a specific case ID.

    Parameters:
    - case_id: Case identifier with suffix (e.g., GSE122080-9737)
    - format: Report format (html or md)

    Returns:
    - case_id: Case identifier
    - content: Parsed report content
    - format: Format of the content
    """
    report_dir = _data_path / "report" / case_id

    if not report_dir.exists():
        logger.warning(f"Report directory not found for {case_id}")
        raise HTTPException(
            status_code=404,
            detail=f"Parsed report not found for {case_id}",
        )

    try:
        if format == "html":
            report_path = report_dir / "parsed_report.html"
        elif format == "md":
            report_path = report_dir / "parsed_report.md"
        else:
            raise HTTPException(status_code=400, detail="Format must be 'html' or 'md'")

        if not report_path.exists():
            raise HTTPException(
                status_code=404,
                detail=f"Parsed report in {format} format not found for {case_id}",
            )

        with open(report_path, "r", encoding="utf-8") as f:
            content = f.read()

        return {
            "case_id": case_id,
            "content": content,
            "format": format,
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error loading parsed report for {case_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/search")
async def search_interventions(
    query: str = Query(..., min_length=2, description="Search query for GSE ID or intervention name"),
    limit: int = Query(50, ge=1, le=500, description="Maximum number of results"),
) -> list[dict[str, Any]]:
    """
    Search for interventions by GSE ID or intervention name.

    Parameters:
    - query: Search term (minimum 2 characters)
    - limit: Maximum number of results to return

    Returns:
    - List of matching interventions with basic info
    """
    try:
        df = get_volcano_data()

        # Case-insensitive search in both gse_id and intervention columns
        query_lower = query.lower()
        mask = df["gse_id"].str.lower().str.contains(query_lower, na=False, regex=False) | df[
            "intervention"
        ].str.lower().str.contains(query_lower, na=False, regex=False)

        results = df[mask].head(limit)

        # Return essential info
        return results[
            [
                "gse_id",
                "case_id",
                "intervention",
                "condition_category",
                "trust_score",
                "fdr",
                "log2FoldChange",
                "has_output_data",
                "has_report",
            ]
        ].to_dict("records")

    except Exception as e:
        logger.error(f"Error searching interventions: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/categories")
async def get_categories() -> dict[str, Any]:
    """
    Get list of all intervention categories and their counts.

    Returns:
    - categories: Dictionary of category names and counts
    """
    try:
        df = get_volcano_data()
        category_counts = df["condition_category"].value_counts().to_dict()

        return {
            "categories": category_counts,
            "total": len(df),
        }

    except Exception as e:
        logger.error(f"Error fetching categories: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/summary")
async def get_summary_stats() -> dict[str, Any]:
    """
    Get overall summary statistics for the interventions dataset.

    Returns:
    - Summary statistics including counts, distributions, etc.
    """
    try:
        df = get_volcano_data()

        return {
            "total_comparisons": len(df),
            "significant_comparisons": int((df["fdr"] < 0.05).sum()),
            "categories": df["condition_category"].value_counts().to_dict(),
            "score_stats": {
                "mean": float(df["trust_score"].mean()),
                "median": float(df["trust_score"].median()),
                "min": float(df["trust_score"].min()),
                "max": float(df["trust_score"].max()),
            },
            "effect_stats": {
                "mean_abs": float(df["log2FoldChange"].abs().mean()),
                "median_abs": float(df["log2FoldChange"].abs().median()),
                "max_positive": float(df["log2FoldChange"].max()),
                "max_negative": float(df["log2FoldChange"].min()),
            },
            "reports_available": {
                "output_data": int(df["has_output_data"].sum()),
                "parsed_reports": int(df["has_report"].sum()),
            },
        }

    except Exception as e:
        logger.error(f"Error fetching summary stats: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/gse/{gse_id}")
async def get_gse_details(gse_id: str) -> dict[str, Any]:
    """
    Get all details for a specific GSE ID from the volcano data.

    Parameters:
    - gse_id: GSE identifier

    Returns:
    - Complete record for the GSE ID
    """
    try:
        df = get_volcano_data()
        records = df[df["gse_id"] == gse_id]

        if records.empty:
            raise HTTPException(
                status_code=404,
                detail=f"No data found for GSE ID: {gse_id}",
            )

        # Return first matching record (there should only be one)
        return records.iloc[0].to_dict()

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching GSE details for {gse_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))
