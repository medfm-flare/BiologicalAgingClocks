# backend/endpoints/metadata.py
from functools import lru_cache
from typing import List, Literal, Optional, Tuple

import pandas as pd
from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel
from loguru import logger


router = APIRouter()

# --- expected columns (will be used to select/normalize output) ---
GEO_COLUMNS = [
    "title",
    "description",
    "organism",
    "type",
    "platform",
    "accession",
    "id",
    "project",
    "dataset",
    "samples",
]


# -----------------------
# Pydantic models
# -----------------------
class GeoMetadata(BaseModel):
    title: Optional[str] = ""
    description: Optional[str] = ""
    organism: Optional[str] = ""
    type: Optional[str] = ""
    platform: Optional[str] = ""
    accession: Optional[str] = ""
    id: Optional[int] = None
    project: Optional[str] = ""
    dataset: Optional[str] = ""
    samples: Optional[str] = ""


class GeoMetadataResponse(BaseModel):
    metadata: List[GeoMetadata]
    total: int


class GeoFilters(BaseModel):
    types: List[str]
    organisms: List[str]


# -----------------------
# Data loading & normalization
# -----------------------
DATA_PARQUET = "./data/gse_all.parquet"
DATA_CSV = "./data/gse_all.csv"

try:
    # prefer parquet for performance if available
    df_all = pd.read_parquet(DATA_PARQUET)
    logger.info("Loaded GEO metadata from parquet")
except Exception as e_parquet:
    logger.debug(f"Parquet load failed: {e_parquet}. Trying CSV...")
    try:
        df_all = pd.read_csv(DATA_CSV)
        logger.info("Loaded GEO metadata from CSV")
    except Exception:
        logger.exception("Failed to load GEO metadata from CSV/Parquet")
        df_all = pd.DataFrame(columns=GEO_COLUMNS)

# Ensure all needed columns exist (create with empty values if missing)
for col in GEO_COLUMNS:
    if col not in df_all.columns:
        df_all[col] = ""

# Normalise types: strings, trim description length to reduce payload
df_all["description"] = df_all["description"].astype(str).fillna("").str.slice(0, 500)
for col in ["title", "organism", "type", "platform", "accession", "project", "dataset", "samples"]:
    df_all[col] = df_all[col].astype(str).fillna("")


# id: try to convert to integer where possible, otherwise None
def safe_int(val):
    try:
        if pd.isna(val):
            return None
        # val may be float-like (e.g., 200122244.0)
        if isinstance(val, float):
            if val.is_integer():
                return int(val)
            return int(val)
        return int(str(val))
    except Exception:
        return None


df_all["id"] = df_all["id"].apply(safe_int)

# Precompute filter lists (cached)
TYPES = sorted(df_all["type"].replace("", pd.NA).dropna().unique().tolist())
ORGANISMS = sorted(df_all["organism"].replace("", pd.NA).dropna().unique().tolist())

logger.info(f"GEO rows: {len(df_all):,}; types={len(TYPES)} organisms={len(ORGANISMS)}")


# -----------------------
# Filtering util (cached)
# -----------------------
@lru_cache(maxsize=256)
def _filter_cached(
    page: int,
    size: int,
    search: Optional[str],
    types: Optional[Tuple[str, ...]],
    organisms: Optional[Tuple[str, ...]],
    sort_key: Optional[str],
    sort_direction: Literal["asc", "desc"],
) -> dict:
    """
    Internal cached filter function.
    Note: all args must be hashable -> lists converted to tuples when called.
    Returns a dict with 'metadata' and 'total'.
    """
    df = df_all

    # 1) search (vectorized across string columns)
    if search:
        q = str(search).strip()
        if q:
            # we only search string/object columns to avoid converting numeric arrays
            str_cols = df.select_dtypes(include=["object", "string"]).columns.tolist()
            if not str_cols:
                mask = pd.Series(False, index=df.index)
            else:
                # create boolean mask by OR-ing per-column contains
                mask = pd.Series(False, index=df.index)
                q_lower = q  # pandas str.contains is case-insensitive with flag below
                for col in str_cols:
                    try:
                        contains = df[col].str.contains(q_lower, case=False, na=False)
                        mask = mask | contains
                    except Exception:
                        # if any column fails (weird types), ignore it
                        logger.debug(f"Skipping search on column {col} due to exception")
                df = df[mask]

    # 2) types filter
    if types:
        df = df[df["type"].isin(types)]

    # 3) organisms filter
    if organisms:
        df = df[df["organism"].isin(organisms)]

    # 4) sorting (safely)
    if sort_key and sort_key in df.columns:
        ascending = sort_direction == "asc"
        try:
            df = df.sort_values(by=sort_key, ascending=ascending, na_position="last")
        except Exception:
            # fallback: string sort
            df = df.sort_values(by=df[sort_key].astype(str), ascending=ascending, na_position="last")

    total = len(df)

    # 5) pagination slice
    start = max((page - 1) * size, 0)
    end = start + size
    slice_df = df.iloc[start:end]

    # 6) select only expected columns and coerce types for safety
    slice_df = slice_df[GEO_COLUMNS].copy()
    # ensure id is native int or None
    slice_df["id"] = slice_df["id"].apply(lambda v: int(v) if (pd.notna(v) and v != "") else None)
    # samples keep as string (frontend expects string sometimes), but normalize empty
    slice_df["samples"] = slice_df["samples"].astype(str).replace("nan", "")

    records = slice_df.where(pd.notna(slice_df), None).to_dict(orient="records")

    return {"metadata": records, "total": total}


# -----------------------
# API endpoints
# -----------------------
@router.get("/geo-metadata", response_model=GeoMetadataResponse)
async def get_geo_metadata(
    page: int = Query(1, ge=1),
    size: int = Query(10, ge=1, le=100),
    search: Optional[str] = Query(None),
    types: Optional[List[str]] = Query(None),
    organisms: Optional[List[str]] = Query(None),
    sort_key: Optional[str] = Query(None),
    sort_direction: Literal["asc", "desc"] = "asc",
):
    """
    Paginated GEO metadata endpoint.
    Returns items that match search/types/organism with safe types.
    """
    try:
        types_tuple = tuple(types) if types else None
        organisms_tuple = tuple(organisms) if organisms else None

        result = _filter_cached(
            page=page,
            size=size,
            search=search,
            types=types_tuple,
            organisms=organisms_tuple,
            sort_key=sort_key,
            sort_direction=sort_direction,
        )
        return GeoMetadataResponse(metadata=result["metadata"], total=result["total"])
    except Exception as e:
        logger.exception("Error in /geo-metadata")
        raise HTTPException(status_code=500, detail=f"Internal error: {e}")


@router.get("/geo-filters", response_model=GeoFilters)
async def get_geo_filters():
    """Return lists of unique types and organisms (cached at startup)."""
    return GeoFilters(types=TYPES, organisms=ORGANISMS)


# small diagnostic endpoint (not required, useful in dev)
@router.get("/geo-metadata/stats")
async def geo_metadata_stats():
    return {"rows": len(df_all), "columns": df_all.columns.tolist()}
