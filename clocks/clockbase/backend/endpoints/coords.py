# backend/endpoints/coords.py
from fastapi import APIRouter, HTTPException, Response
from pathlib import Path
import pandas as pd
import pyarrow as pa
import pyarrow.ipc as ipc
from loguru import logger

router = APIRouter()
COORDS_DIR = Path("./data/3dcoords_parquet")

ANALYSIS_FILES = {
    "DunedinPACE_tsne": "human_dnam_acc_tsne_DunedinPACE_coords.parquet",
    "DunedinPoAm_tsne": "human_dnam_acc_tsne_DunedinPoAm_coords.parquet",
    "HannumAge_tsne": "human_dnam_acc_tsne_HannumAge_coords.parquet",
    "HorvathAge_tsne": "human_dnam_acc_tsne_HorvathAge_coords.parquet",
    "PedBE_tsne": "human_dnam_acc_tsne_PedBE_coords.parquet",
    "PhenoAge_tsne": "human_dnam_acc_tsne_PhenoAge_coords.parquet",
    "ZhangAge_tsne": "human_dnam_acc_tsne_ZhangAge_coords.parquet",
    "DunedinPACE_umap": "human_dnam_umap_DunedinPACE_coords.parquet",
    "DunedinPoAm_umap": "human_dnam_umap_DunedinPoAm_coords.parquet",
    "HannumAge_umap": "human_dnam_umap_HannumAge_coords.parquet",
    "HorvathAge_umap": "human_dnam_umap_HorvathAge_coords.parquet",
    "PedBE_umap": "human_dnam_umap_PedBE_coords.parquet",
    "PhenoAge_umap": "human_dnam_umap_PhenoAge_coords.parquet",
    "ZhangAge_umap": "human_dnam_umap_ZhangAge_coords.parquet",
    "DunedinPACE_umap_lite": "human_dnam_umap_lite_DunedinPACE_coords.parquet",
    "DunedinPoAm_umap_lite": "human_dnam_umap_lite_DunedinPoAm_coords.parquet",
    "HannumAge_umap_lite": "human_dnam_umap_lite_HannumAge_coords.parquet",
    "HorvathAge_umap_lite": "human_dnam_umap_lite_HorvathAge_coords.parquet",
    "PedBE_umap_lite": "human_dnam_umap_lite_PedBE_coords.parquet",
    "PhenoAge_umap_lite": "human_dnam_umap_lite_PhenoAge_coords.parquet",
    "ZhangAge_umap_lite": "human_dnam_umap_lite_ZhangAge_coords.parquet",
}

CACHE = {}


def load_parquet_cached(path: Path) -> pd.DataFrame:
    if path not in CACHE:
        df = pd.read_parquet(path)
        CACHE[path] = df
    return CACHE[path]


@router.get("/coordinates_bin")
async def get_coordinates_bin(
    analysis: str,
    method: str = "tsne",
    level: int = 15000,
):
    key = f"{analysis}_{method}"
    if key not in ANALYSIS_FILES:
        raise HTTPException(status_code=400, detail=f"Invalid key: {key}")
    path = COORDS_DIR / ANALYSIS_FILES[key]
    if not path.exists():
        raise HTTPException(status_code=404, detail="File not found")

    try:
        df = load_parquet_cached(path)
        cols = ["x", "y", "z", "Delta_Age", "GEO", "GSM", "title", "source_name", "sex", "age", "specimen_part", "race"]
        df = df[[c for c in cols if c in df.columns]].dropna(subset=["x", "y", "z"])
        if len(df) > level:
            df = df.sample(level, random_state=42)

        table = pa.Table.from_pandas(df)
        sink = pa.BufferOutputStream()
        with ipc.new_stream(sink, table.schema) as writer:
            writer.write_table(table)
        buf = sink.getvalue().to_pybytes()
        return Response(content=buf, media_type="application/vnd.apache.arrow.stream")
    except Exception as e:
        logger.exception(e)
        raise HTTPException(status_code=500, detail=str(e))
