"""Plot endpoints for ClockBase API with improved error handling and caching."""

from io import BytesIO
from typing import Optional

import matplotlib

matplotlib.use("Agg")  # Non-GUI backend
import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns
from fastapi import APIRouter, HTTPException, Query
from fastapi.responses import JSONResponse, StreamingResponse
from scipy.stats import f_oneway, pearsonr, spearmanr
from statsmodels.stats.multicomp import pairwise_tukeyhsd
from loguru import logger

from endpoints.gse import get_gse_df

router = APIRouter()


# ============================================================================
# Statistical Functions
# ============================================================================


def _calculate_correlation_stats(x_data: pd.Series, y_data: pd.Series) -> dict:
    """Calculate Pearson and Spearman correlations with R²."""
    if len(x_data) < 2:
        raise ValueError("At least 2 data points required for correlation")

    pearson_r, pearson_p = pearsonr(x_data, y_data)
    spearman_r, spearman_p = spearmanr(x_data, y_data)

    return {
        "pearson_r": float(pearson_r),
        "pearson_p": float(pearson_p),
        "spearman_r": float(spearman_r),
        "spearman_p": float(spearman_p),
        "r_squared": float(pearson_r**2),
    }


def _format_label(label: str) -> str:
    """Format label: replace underscores and title case."""
    return label.replace("_", " ").title()


def _format_stats_text(stats: dict, group_name: Optional[str] = None, n: int = 0) -> str:
    """Format correlation statistics for plot annotation."""
    parts = []
    if group_name:
        parts.append(f"{group_name}:")

    parts.extend(
        [
            f"R² = {stats['r_squared']:.3f}",
            f"Pearson r = {stats['pearson_r']:.3f} (p={stats['pearson_p']:.3e})",
            f"Spearman ρ = {stats['spearman_r']:.3f} (p={stats['spearman_p']:.3e})",
            f"n = {n}",
        ]
    )

    return "\n".join(parts)


def _plot_scatter_with_regression(
    ax: plt.Axes,
    df: pd.DataFrame,
    x_col: str,
    y_col: str,
    color: str,
    label: Optional[str] = None,
    show_ci: bool = True,
) -> None:
    """Create scatter plot with regression line."""
    ax.scatter(
        df[x_col],
        df[y_col],
        c=[color],
        alpha=0.7,
        s=60,
        edgecolors="white",
        linewidth=0.5,
        label=label,
    )

    if show_ci and len(df) > 3:
        sns.regplot(
            x=x_col,
            y=y_col,
            data=df,
            scatter=False,
            ax=ax,
            color=color,
            ci=95,
            line_kws={"linewidth": 2},
        )


def _add_stats_annotation(ax: plt.Axes, text: str, y_pos: float, color: str) -> None:
    """Add statistics text box to plot."""
    ax.text(
        0.02,
        y_pos,
        text,
        transform=ax.transAxes,
        fontsize=9,
        verticalalignment="top",
        bbox=dict(boxstyle="round,pad=0.3", facecolor=color, alpha=0.2, edgecolor=color),
    )


def _create_dataset_info_text(df: pd.DataFrame, gse: str, subgroup: Optional[str]) -> str:
    """Create dataset information text."""
    parts = [f"Dataset: {gse}", f"Total samples: {len(df)}"]
    if subgroup and subgroup in df.columns:
        counts = df[subgroup].value_counts()
        parts.append(f"Groups: {', '.join([f'{k}={v}' for k, v in counts.items()])}")
    return "\n".join(parts)


# ============================================================================
# Data Endpoints for Interactive Frontend
# ============================================================================


@router.get("/plot-data/correlation/{gse}")
async def get_correlation_data(
    gse: str,
    x_label: str = Query(..., description="X-axis column name"),
    y_label: str = Query(..., description="Y-axis column name"),
    subgroup: Optional[str] = Query(None, description="Subgroup column name"),
) -> JSONResponse:
    """Get correlation data for interactive plotting."""
    try:
        df = get_gse_df(gse)

        # Validate columns
        if x_label not in df.columns:
            raise ValueError(f"Column '{x_label}' not found in dataset")
        if y_label not in df.columns:
            raise ValueError(f"Column '{y_label}' not found in dataset")
        if subgroup and subgroup not in df.columns:
            raise ValueError(f"Subgroup column '{subgroup}' not found in dataset")

        # Prepare data points
        data_points = []
        for _, row in df.iterrows():
            point = {
                "x": float(row[x_label]) if pd.notna(row[x_label]) else None,
                "y": float(row[y_label]) if pd.notna(row[y_label]) else None,
            }
            if subgroup:
                point["group"] = str(row[subgroup]) if pd.notna(row[subgroup]) else "Unknown"
            data_points.append(point)

        # Calculate overall stats
        valid_data = df[[x_label, y_label]].dropna()
        overall_stats = None
        if len(valid_data) > 1:
            overall_stats = _calculate_correlation_stats(valid_data[x_label], valid_data[y_label])
            overall_stats["n"] = len(valid_data)

        # Calculate per-group stats
        group_stats = {}
        if subgroup:
            for group_name in df[subgroup].unique():
                group_data = df[df[subgroup] == group_name][[x_label, y_label]].dropna()
                if len(group_data) > 1:
                    group_stats[str(group_name)] = _calculate_correlation_stats(group_data[x_label], group_data[y_label])
                    group_stats[str(group_name)]["n"] = len(group_data)

        return JSONResponse(
            content={
                "data": data_points,
                "stats": {
                    "overall": overall_stats,
                    "groups": group_stats if group_stats else None,
                },
                "labels": {
                    "x": _format_label(x_label),
                    "y": _format_label(y_label),
                    "title": f"{_format_label(x_label)} vs {_format_label(y_label)}",
                },
                "metadata": {
                    "gse": gse,
                    "total_samples": len(df),
                    "valid_samples": len(valid_data),
                    "has_subgroups": subgroup is not None,
                },
            }
        )

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal error: {str(e)}")


@router.get("/plot-data/comparison/{gse}")
async def get_comparison_data(
    gse: str,
    x_label: str = Query(..., description="Numeric variable column name"),
    y_label: str = Query(..., description="Grouping variable column name"),
    subgroup: Optional[str] = Query(None, description="Additional subgroup column name"),
) -> JSONResponse:
    """Get group comparison data with ANOVA statistics."""
    try:
        df = get_gse_df(gse)

        # Validate columns
        if x_label not in df.columns:
            raise ValueError(f"Column '{x_label}' not found in dataset")
        if y_label not in df.columns:
            raise ValueError(f"Column '{y_label}' not found in dataset")

        unique_groups = df[y_label].unique()
        if len(unique_groups) < 2:
            raise ValueError("At least 2 groups required for comparison")

        # Prepare data points
        data_points = []
        for _, row in df.iterrows():
            point = {
                "value": float(row[x_label]) if pd.notna(row[x_label]) else None,
                "group": str(row[y_label]) if pd.notna(row[y_label]) else "Unknown",
            }
            if subgroup and subgroup in df.columns:
                point["subgroup"] = str(row[subgroup]) if pd.notna(row[subgroup]) else "Unknown"
            data_points.append(point)

        # ANOVA
        groups = [df[df[y_label] == g][x_label].dropna() for g in unique_groups]
        anova_result = f_oneway(*groups)
        anova_p = float(anova_result.pvalue)

        # Tukey HSD
        valid_df = df[[x_label, y_label]].dropna()
        tukey_result = pairwise_tukeyhsd(valid_df[x_label], valid_df[y_label])

        tukey_comparisons = []
        for row in tukey_result.summary().data[1:]:
            tukey_comparisons.append(
                {
                    "group1": str(row[0]),
                    "group2": str(row[1]),
                    "meandiff": float(row[2]),
                    "p_adj": float(row[3]),
                    "lower": float(row[4]),
                    "upper": float(row[5]),
                    "reject": bool(row[6]),
                }
            )

        # Group statistics
        group_stats = {}
        for group in unique_groups:
            vals = df[df[y_label] == group][x_label].dropna()
            group_stats[str(group)] = {
                "n": int(len(vals)),
                "mean": float(vals.mean()),
                "std": float(vals.std()),
                "median": float(vals.median()),
                "min": float(vals.min()),
                "max": float(vals.max()),
            }

        return JSONResponse(
            content={
                "data": data_points,
                "stats": {
                    "anova_p_value": anova_p,
                    "tukey_comparisons": tukey_comparisons,
                    "group_statistics": group_stats,
                },
                "labels": {
                    "x": _format_label(y_label),
                    "y": _format_label(x_label),
                    "title": f"{_format_label(x_label)} across {_format_label(y_label)}",
                },
                "metadata": {
                    "gse": gse,
                    "total_samples": len(df),
                    "n_groups": len(unique_groups),
                    "groups": [str(g) for g in unique_groups],
                },
            }
        )

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal error: {str(e)}")


# ============================================================================
# Legacy Image-based Endpoints
# ============================================================================


@router.get("/plot/correlation/{gse}")
async def plot_correlation(
    gse: str,
    x_label: str = Query(..., description="X-axis column name"),
    y_label: str = Query(..., description="Y-axis column name"),
    subgroup: Optional[str] = Query(None, description="Subgroup column name"),
    plot_style: str = Query("darkgrid", description="Seaborn style"),
    confidence_interval: bool = Query(True, description="Show 95% CI"),
) -> StreamingResponse:
    """Generate static correlation plot image (LEGACY)."""
    try:
        df = get_gse_df(gse)
        sns.set_style(plot_style)

        # Validate columns
        if x_label not in df.columns or y_label not in df.columns:
            raise ValueError("Columns not found in dataset")

        fig, ax = plt.subplots(figsize=(10, 8))

        # Setup colors
        if subgroup and subgroup in df.columns:
            unique_groups = df[subgroup].unique()
            colors = sns.color_palette("viridis", len(unique_groups))
        else:
            colors = ["#2E86AB"]

        # Plot data
        if subgroup and subgroup in df.columns:
            for i, group in enumerate(unique_groups):
                group_data = df[df[subgroup] == group]
                _plot_scatter_with_regression(
                    ax, group_data, x_label, y_label, colors[i], label=group, show_ci=confidence_interval
                )

                if len(group_data) > 1:
                    stats = _calculate_correlation_stats(group_data[x_label], group_data[y_label])
                    text = _format_stats_text(stats, group, len(group_data))
                    _add_stats_annotation(ax, text, 0.95 - (i * 0.15), colors[i])
        else:
            _plot_scatter_with_regression(ax, df, x_label, y_label, colors[0], show_ci=confidence_interval)

            if len(df) > 1:
                stats = _calculate_correlation_stats(df[x_label], df[y_label])
                text = _format_stats_text(stats, n=len(df))
                _add_stats_annotation(ax, text, 0.98, colors[0])

        # Formatting
        ax.set_xlabel(_format_label(x_label), fontsize=12, fontweight="bold")
        ax.set_ylabel(_format_label(y_label), fontsize=12, fontweight="bold")
        ax.set_title(
            f"Correlation: {_format_label(x_label)} vs {_format_label(y_label)}",
            fontsize=14,
            fontweight="bold",
            pad=20,
        )
        ax.grid(True, alpha=0.3)

        if subgroup:
            ax.legend(loc="upper right", frameon=True, fancybox=True, shadow=True)

        # Save
        buf = BytesIO()
        plt.savefig(buf, format="png", bbox_inches="tight", dpi=300, facecolor="white")
        plt.close(fig)
        buf.seek(0)

        return StreamingResponse(buf, media_type="image/png")

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal error: {str(e)}")


@router.get("/plot/comparison/{gse}")
async def plot_comparison(
    gse: str,
    x_label: str = Query(..., description="Numeric variable column name"),
    y_label: str = Query(..., description="Grouping variable column name"),
    subgroup: Optional[str] = Query(None, description="Additional subgroup column name"),
) -> StreamingResponse:
    """Generate static group comparison plot (LEGACY)."""
    try:
        logger.info(
            f"Generating comparison plot for GSE: {gse}, x_label: {x_label}, y_label: {y_label}, subgroup: {subgroup}"
        )
        df = get_gse_df(gse)
        logger.info(f"Dataframe loaded with {len(df)} rows and {len(df.columns)} columns")
        logger.info(f"Columns in dataframe: {df.columns.tolist()}")

        if x_label not in df.columns or y_label not in df.columns:
            raise ValueError("Columns not found in dataset")

        unique_groups = df[y_label].unique()
        if len(unique_groups) < 2:
            raise ValueError("At least 2 groups required")

        fig, ax = plt.subplots(figsize=(10, 7))

        # Violin plot
        sns.violinplot(
            data=df,
            x=y_label,
            y=x_label,
            hue=subgroup if subgroup and subgroup in df.columns else None,
            palette="viridis",
            inner="box",
            alpha=0.6,
            ax=ax,
        )

        # Strip plot overlay
        sns.stripplot(
            data=df,
            x=y_label,
            y=x_label,
            hue=subgroup if subgroup and subgroup in df.columns else None,
            dodge=True if subgroup and subgroup in df.columns else False,
            alpha=0.7,
            size=5,
            linewidth=0.5,
            edgecolor="black",
            palette="viridis",
            ax=ax,
            legend=False,
        )

        # Labels
        ax.set_xlabel(_format_label(y_label), fontsize=12, fontweight="bold")
        ax.set_ylabel(_format_label(x_label), fontsize=12, fontweight="bold")
        ax.set_title(
            f"{_format_label(x_label)} across {_format_label(y_label)}",
            fontsize=14,
            fontweight="bold",
        )
        ax.grid(True, axis="y", alpha=0.3)

        # ANOVA
        groups = [df[df[y_label] == g][x_label].dropna() for g in unique_groups]
        anova_p = f_oneway(*groups).pvalue

        ax.text(
            0.5,
            0.95,
            f"ANOVA p = {anova_p:.4e}",
            ha="center",
            va="top",
            transform=ax.transAxes,
            fontsize=11,
            fontweight="bold" if anova_p < 0.05 else "normal",
            bbox=dict(boxstyle="round,pad=0.5", facecolor="yellow" if anova_p < 0.05 else "white", alpha=0.7),
        )

        # Save
        buf = BytesIO()
        plt.savefig(buf, format="png", bbox_inches="tight", dpi=300, facecolor="white")
        plt.close(fig)
        buf.seek(0)

        return StreamingResponse(buf, media_type="image/png")

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal error: {str(e)}")


@router.get("/stats/comparison/{gse}")
async def get_comparison_stats(
    gse: str,
    x_label: str = Query(..., description="Numeric variable column name"),
    y_label: str = Query(..., description="Grouping variable column name"),
) -> JSONResponse:
    """Get ANOVA and Tukey HSD statistics (LEGACY)."""
    try:
        df = get_gse_df(gse)

        if x_label not in df.columns or y_label not in df.columns:
            raise ValueError("Columns not found")

        unique_groups = df[y_label].unique()
        if len(unique_groups) < 2:
            raise ValueError("At least 2 groups required")

        # ANOVA
        groups = [df[df[y_label] == g][x_label].dropna() for g in unique_groups]
        anova_p = f_oneway(*groups).pvalue

        # Tukey HSD
        valid_df = df[[x_label, y_label]].dropna()
        tukey = pairwise_tukeyhsd(valid_df[x_label], valid_df[y_label])

        summary = tukey.summary().data
        headers = summary[0]
        data = []
        colors = []

        for row in summary[1:]:
            data.append(
                [
                    str(row[0]),
                    str(row[1]),
                    f"{row[2]:.4f}",
                    f"{row[3]:.4e}",
                    f"{row[4]:.4f}",
                    f"{row[5]:.4f}",
                    "Yes" if row[6] else "No",
                ]
            )
            colors.append("lightgreen" if row[6] else "white")

        return JSONResponse(
            content={
                "anova_p_value": f"{anova_p:.4e}",
                "headers": headers,
                "data": data,
                "row_colors": colors,
            }
        )

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Internal error: {str(e)}")
