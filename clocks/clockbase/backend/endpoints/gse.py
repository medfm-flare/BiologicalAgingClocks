"""GSE data endpoints with improved caching and error handling."""

from pathlib import Path
from typing import Optional

import pandas as pd
from fastapi import APIRouter, HTTPException, Query

router = APIRouter()

# Configuration
DATA_DIR = Path("./data")

# Subdirectories to search for GSE data
SEARCH_DIRS = [
    "GEO_hs_dnam",
    "GEO_mm_dnam",
    "GEO_hs_rna",
    "GEO_mm_rna",
]

# Cache for loaded data to avoid repeated disk reads
_data_cache = {}


# ============================================================================
# Helper Functions
# ============================================================================


def _get_gse_path(gse: str, mode: str) -> Optional[Path]:
    """
    Find the path to a GSE file in the data directory.

    Parameters
    ----------
    gse : str
        GSE identifier (e.g., "GSE40279")
    mode : str
        Type of data: "processed_metadata" or "clock_result"

    Returns
    -------
    Optional[Path]
        Path to the parquet file, or None if not found
    """
    for subdir in SEARCH_DIRS:
        dir_path = DATA_DIR / subdir / mode

        if not dir_path.exists():
            continue

        try:
            for file in dir_path.iterdir():
                if file.name.startswith(gse) and file.suffix == ".parquet":
                    return file
        except (PermissionError, OSError):
            continue

    return None


def _load_parquet_with_cache(cache_key: str, file_path: Path) -> pd.DataFrame:
    """
    Load parquet file with caching.

    Parameters
    ----------
    cache_key : str
        Unique identifier for cache
    file_path : Path
        Path to parquet file

    Returns
    -------
    pd.DataFrame
        Loaded dataframe
    """
    if cache_key not in _data_cache:
        df = pd.read_parquet(file_path)
        _data_cache[cache_key] = df

    return _data_cache[cache_key].copy()


def _normalize_sample_id_column(df: pd.DataFrame) -> pd.DataFrame:
    """
    Normalize sample ID column to 'sample_id'.

    Handles various naming conventions:
    - Unnamed: 0
    - index
    - GSM

    Parameters
    ----------
    df : pd.DataFrame
        Input dataframe

    Returns
    -------
    pd.DataFrame
        Dataframe with normalized 'sample_id' column
    """
    if "sample_id" in df.columns:
        return df

    # Check for common alternative names
    alternatives = ["Unnamed: 0", "index", "GSM"]

    for alt in alternatives:
        if alt in df.columns:
            return df.rename(columns={alt: "sample_id"})

    # If no alternative found, use index as sample_id
    df_copy = df.copy()
    df_copy["sample_id"] = df_copy.index.astype(str)
    return df_copy


def _merge_predictions_and_metadata(
    df_pred: pd.DataFrame,
    df_meta: pd.DataFrame,
) -> pd.DataFrame:
    """
    Merge clock predictions with metadata.

    Parameters
    ----------
    df_pred : pd.DataFrame
        Clock predictions dataframe
    df_meta : pd.DataFrame
        Metadata dataframe

    Returns
    -------
    pd.DataFrame
        Merged dataframe
    """
    # Normalize column names
    df_pred = _normalize_sample_id_column(df_pred)
    df_meta = _normalize_sample_id_column(df_meta)

    # Merge on sample_id
    df_merged = pd.merge(
        df_pred,
        df_meta,
        how="left",
        left_on="sample_id",
        right_on="sample_id",
        suffixes=("", "_meta"),
    )

    # Fill NaN with empty strings for frontend compatibility
    df_merged = df_merged.fillna("")

    return df_merged


# ============================================================================
# Public API Functions
# ============================================================================


def get_gse_df(gse_id: str) -> pd.DataFrame:
    """
    Load GSE dataset with clock predictions.

    Used by other endpoints (e.g., plots) to get preprocessed data.

    Parameters
    ----------
    gse_id : str
        GSE identifier

    Returns
    -------
    pd.DataFrame
        Dataframe with clock predictions

    Raises
    ------
    HTTPException
        If GSE data not found
    """
    cache_key = f"clock_{gse_id}"

    # Check cache first
    if cache_key in _data_cache:
        return _data_cache[cache_key].copy()

    # Find and load file
    gse_path = _get_gse_path(gse_id, mode="clock_result")
    get_gse_metadata_path = _get_gse_path(gse_id, mode="processed_metadata")

    if gse_path is None:
        raise HTTPException(status_code=404, detail=f"Clock predictions for GSE '{gse_id}' not found")

    try:
        df = _load_parquet_with_cache(cache_key, gse_path)
        df_metadata = None
        if get_gse_metadata_path is not None:
            df_metadata = _load_parquet_with_cache(f"meta_{gse_id}", get_gse_metadata_path)
        if df_metadata is not None:
            df = _merge_predictions_and_metadata(df, df_metadata)
        df = _normalize_sample_id_column(df)
        return df
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to load clock predictions: {str(e)}")


def load_metadata(gse: str) -> pd.DataFrame:
    """
    Load metadata for a GSE dataset.

    Parameters
    ----------
    gse : str
        GSE identifier

    Returns
    -------
    pd.DataFrame
        Metadata dataframe

    Raises
    ------
    HTTPException
        If metadata not found
    """
    cache_key = f"meta_{gse}"

    # Check cache
    if cache_key in _data_cache:
        return _data_cache[cache_key].copy()

    # Find and load file
    gse_path = _get_gse_path(gse, mode="processed_metadata")

    if gse_path is None:
        raise HTTPException(status_code=404, detail=f"Metadata for GSE '{gse}' not found")

    try:
        df = _load_parquet_with_cache(cache_key, gse_path)
        df = _normalize_sample_id_column(df)
        return df
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to load metadata: {str(e)}")


# ============================================================================
# API Endpoints
# ============================================================================


@router.get("/gse/{gse_id}")
async def read_gse(
    gse_id: str,
    include_metadata: bool = Query(True, description="Include metadata fields"),
) -> list[dict]:
    """
    Get merged GSE data (clock predictions + metadata).

    Returns a list of sample records with clock predictions and metadata.

    Parameters
    ----------
    gse_id : str
        GSE identifier
    include_metadata : bool, optional
        Whether to include metadata (default: True)

    Returns
    -------
    list[dict]
        List of sample records

    Raises
    ------
    HTTPException
        404 if GSE not found
        500 if processing fails
    """
    try:
        # Load clock predictions
        df_pred = get_gse_df(gse_id)

        if not include_metadata:
            return df_pred.to_dict(orient="records")

        # Load metadata
        try:
            df_meta = load_metadata(gse_id)
        except HTTPException as e:
            # If metadata not found, return predictions only
            if e.status_code == 404:
                return df_pred.to_dict(orient="records")
            raise

        # Merge
        df_merged = _merge_predictions_and_metadata(df_pred, df_meta)

        if df_merged.empty:
            raise HTTPException(status_code=404, detail=f"No data found for GSE '{gse_id}' after merge")

        return df_merged.to_dict(orient="records")

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to process GSE data: {str(e)}")


@router.get("/gse/{gse_id}/metadata")
async def get_gse_metadata(
    gse_id: str,
) -> list[dict]:
    """
    Get only metadata for a GSE dataset.

    Parameters
    ----------
    gse_id : str
        GSE identifier

    Returns
    -------
    list[dict]
        List of metadata records
    """
    df = load_metadata(gse_id)
    return df.to_dict(orient="records")


@router.get("/gse/{gse_id}/clocks")
async def get_gse_clocks(
    gse_id: str,
) -> list[dict]:
    """
    Get only clock predictions for a GSE dataset.

    Parameters
    ----------
    gse_id : str
        GSE identifier

    Returns
    -------
    list[dict]
        List of clock prediction records
    """
    df = get_gse_df(gse_id)
    return df.to_dict(orient="records")


@router.get("/gse/{gse_id}/columns")
async def get_gse_columns(
    gse_id: str,
) -> dict:
    """
    Get column information for a GSE dataset.

    Returns column names categorized by type.

    Parameters
    ----------
    gse_id : str
        GSE identifier

    Returns
    -------
    dict
        Dictionary with column categories:
        - all: All column names
        - clocks: Clock prediction columns
        - metadata: Metadata columns
    """
    # Load data
    df_pred = get_gse_df(gse_id)

    try:
        df_meta = load_metadata(gse_id)
    except HTTPException:
        df_meta = None

    clock_columns = [col for col in df_pred.columns if col != "sample_id"]

    if df_meta is not None:
        metadata_columns = [col for col in df_meta.columns if col != "sample_id"]
        all_columns = list(set(clock_columns + metadata_columns))
    else:
        metadata_columns = []
        all_columns = clock_columns

    return {
        "all": sorted(all_columns),
        "clocks": sorted(clock_columns),
        "metadata": sorted(metadata_columns),
        "sample_id_column": "sample_id",
    }


@router.delete("/cache")
async def clear_cache() -> dict:
    """
    Clear the data cache.

    Useful for development/testing or when data files are updated.

    Returns
    -------
    dict
        Status message with number of items cleared
    """
    global _data_cache
    count = len(_data_cache)
    _data_cache.clear()

    return {
        "status": "success",
        "message": f"Cleared {count} cached items",
    }
