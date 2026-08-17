import React, { useMemo, useCallback, useState } from 'react';
import Plot from 'react-plotly.js';

const MAX_POINTS_BEFORE_DOWNSAMPLING = 5000;
const DOWNSAMPLING_TARGET = 3000;
const USE_WEBGL_THRESHOLD = 2000;

const VolcanoPlot = ({ data, onPointClick, selectedGseId, loading }) => {
  const [isDownsampled, setIsDownsampled] = useState(false);

  const categoryConfig = useMemo(() => ({
    colors: {
      'Genetic': '#3498db',
      'Drug': '#9b59b6',
      'Environment': '#e67e22',
      'Disease': '#e74c3c',
      'Other': '#95a5a6'
    },
    markers: {
      'Genetic': 'circle',
      'Drug': 'diamond',
      'Environment': 'circle',
      'Disease': 'triangle-up',
      'Other': 'x'
    }
  }), []);

  const downsampledData = useMemo(() => {
    if (!data || data.length <= MAX_POINTS_BEFORE_DOWNSAMPLING) {
      setIsDownsampled(false);
      return data;
    }

    setIsDownsampled(true);

    const significant = data.filter(p => p.fdr < 0.05);
    const nonSignificant = data.filter(p => p.fdr >= 0.05);

    const targetNonSignificant = Math.max(
      DOWNSAMPLING_TARGET - significant.length,
      Math.floor(DOWNSAMPLING_TARGET * 0.3)
    );

    const step = Math.ceil(nonSignificant.length / targetNonSignificant);
    const sampledNonSignificant = nonSignificant.filter((_, i) => i % step === 0);

    return [...significant, ...sampledNonSignificant];
  }, [data]);

  const useWebGL = useMemo(() => {
    return downsampledData && downsampledData.length > USE_WEBGL_THRESHOLD;
  }, [downsampledData]);

  const plotData = useMemo(() => {
    if (!downsampledData || downsampledData.length === 0) return [];

    const categoriesMap = new Map();
    const categoryColors = categoryConfig.colors;
    const categoryMarkers = categoryConfig.markers;

    Object.keys(categoryColors).forEach(cat => {
      categoriesMap.set(cat, []);
    });

    downsampledData.forEach(point => {
      const category = point.condition_category || 'Other';
      const arr = categoriesMap.get(category);
      if (arr) arr.push(point);
    });

    const traces = [];
    
    categoriesMap.forEach((points, category) => {
      if (points.length === 0) return;

      const x = new Float64Array(points.length);
      const y = new Float64Array(points.length);
      const sizes = new Float32Array(points.length);
      const colors = new Array(points.length);
      const opacities = new Float32Array(points.length);
      const lineColors = new Array(points.length);
      const lineWidths = new Float32Array(points.length);
      const texts = new Array(points.length);
      const customdata = new Array(points.length);

      const baseColor = categoryColors[category];
      const isSelectedGse = selectedGseId !== null;

      for (let i = 0; i < points.length; i++) {
        const p = points[i];
        const selected = isSelectedGse && p.gse_id === selectedGseId;

        x[i] = p.log2FoldChange || 0;
        y[i] = p.neg_log10_fdr || 0;
        sizes[i] = Math.max(6, Math.min(22, p.marker_size || 10));
        colors[i] = selected ? '#FFD700' : baseColor;
        opacities[i] = selected ? 1.0 : (p.marker_opacity || 0.65);
        lineColors[i] = selected ? '#FF4500' : 'rgba(255,255,255,0.3)';
        lineWidths[i] = selected ? 3 : 0.5;
        texts[i] = createHoverText(p);
        customdata[i] = {
          gse_id: p.gse_id,
          intervention: p.intervention,
          has_output: p.has_output_data,
          has_report: p.has_report
        };
      }

      traces.push({
        x: Array.from(x),
        y: Array.from(y),
        mode: 'markers',
        type: useWebGL ? 'scattergl' : 'scatter',
        name: category,
        marker: {
          size: Array.from(sizes),
          color: colors,
          opacity: Array.from(opacities),
          symbol: categoryMarkers[category],
          line: {
            color: lineColors,
            width: Array.from(lineWidths)
          }
        },
        text: texts,
        hoverinfo: 'text',
        customdata: customdata,
      });
    });

    const maxX = Math.max(...downsampledData.map(p => Math.abs(p.log2FoldChange || 0))) * 1.1 || 30;
    const maxY = Math.max(...downsampledData.map(p => p.neg_log10_fdr || 0)) * 1.1 || 15;

    traces.push({
      x: [-maxX, maxX],
      y: [-Math.log10(0.05), -Math.log10(0.05)],
      mode: 'lines',
      type: useWebGL ? 'scattergl' : 'scatter',
      name: 'FDR = 0.05',
      line: {
        color: 'rgba(255, 255, 255, 0.35)',
        width: 2,
        dash: 'dash'
      },
      hoverinfo: 'skip',
      showlegend: true
    });

    traces.push({
      x: [2, 2],
      y: [0, maxY],
      mode: 'lines',
      type: useWebGL ? 'scattergl' : 'scatter',
      name: '2-fold',
      line: {
        color: 'rgba(255, 255, 255, 0.25)',
        width: 1.5,
        dash: 'dot'
      },
      hoverinfo: 'skip',
      showlegend: true
    });

    traces.push({
      x: [-2, -2],
      y: [0, maxY],
      mode: 'lines',
      type: useWebGL ? 'scattergl' : 'scatter',
      name: '-2-fold',
      line: {
        color: 'rgba(255, 255, 255, 0.25)',
        width: 1.5,
        dash: 'dot'
      },
      hoverinfo: 'skip',
      showlegend: false
    });

    return traces;
  }, [downsampledData, selectedGseId, useWebGL, categoryConfig]);

  const layout = useMemo(() => {
    const maxX = downsampledData && downsampledData.length > 0
      ? Math.max(...downsampledData.map(p => Math.abs(p.log2FoldChange || 0))) * 1.1
      : 30;
    const maxY = downsampledData && downsampledData.length > 0
      ? Math.max(...downsampledData.map(p => p.neg_log10_fdr || 0)) * 1.1
      : 15;

    return {
      title: {
        text: 'Mouse RNA-seq Aging Interventions',
        font: {
          size: 18,
          color: 'white',
          weight: 600
        }
      },
      xaxis: {
        title: {
          text: 'Log2 Effect Size',
          font: { size: 14, color: 'rgba(255,255,255,0.85)' }
        },
        range: [-maxX, maxX],
        gridcolor: 'rgba(255, 255, 255, 0.08)',
        zerolinecolor: 'rgba(255, 255, 255, 0.25)',
        color: 'rgba(255,255,255,0.8)',
        tickfont: { size: 12 }
      },
      yaxis: {
        title: {
          text: '-log10(FDR)',
          font: { size: 14, color: 'rgba(255,255,255,0.85)' }
        },
        range: [0, maxY],
        gridcolor: 'rgba(255, 255, 255, 0.08)',
        zerolinecolor: 'rgba(255, 255, 255, 0.25)',
        color: 'rgba(255,255,255,0.8)',
        tickfont: { size: 12 }
      },
      hovermode: 'closest',
      showlegend: true,
      legend: {
        x: 1.01,
        y: 1,
        xanchor: 'left',
        bgcolor: 'rgba(0, 0, 0, 0.6)',
        bordercolor: 'rgba(255, 255, 255, 0.2)',
        borderwidth: 1,
        font: {
          color: 'white',
          size: 11
        }
      },
      plot_bgcolor: 'rgba(0, 0, 0, 0.25)',
      paper_bgcolor: 'rgba(0, 0, 0, 0)',
      margin: { l: 65, r: 140, t: 60, b: 60 },
      autosize: true
    };
  }, [downsampledData]);

  const config = useMemo(() => ({
    responsive: true,
    displayModeBar: true,
    displaylogo: false,
    modeBarButtonsToAdd: [],
    modeBarButtonsToRemove: ['lasso2d', 'select2d'],
    toImageButtonOptions: {
      format: 'svg',
      filename: 'volcano_plot',
      height: 1000,
      width: 1400,
      scale: 1
    },
    scrollZoom: true,
    doubleClick: 'reset'
  }), []);

  const handleClick = useCallback((event) => {
    if (!event.points || event.points.length === 0) return;
    
    const point = event.points[0];
    
    if (!point.customdata || typeof point.customdata !== 'object') return;
    
    const customdata = point.customdata;
    if (customdata.gse_id && typeof customdata.gse_id === 'string') {
      onPointClick(customdata.gse_id);
    }
  }, [onPointClick]);

  if (loading) {
    return (
      <div style={styles.loading}>
        <div style={styles.loadingSpinner}></div>
        <div style={styles.loadingText}>Loading volcano plot data...</div>
      </div>
    );
  }

  if (!data || data.length === 0) {
    return (
      <div style={styles.empty}>
        <div style={styles.emptyIcon}>📊</div>
        <div style={styles.emptyText}>No data available. Adjust filters to see results.</div>
      </div>
    );
  }

  return (
    <div style={styles.plotContainer}>
      <Plot
        data={plotData}
        layout={layout}
        config={config}
        onClick={handleClick}
        style={{ width: '100%', height: '100%' }}
        useResizeHandler={true}
      />
      
      <div style={styles.stats}>
        <span>Total: <strong>{data.length.toLocaleString()}</strong></span>
        {isDownsampled && (
          <span>Shown: <strong>{downsampledData.length.toLocaleString()}</strong></span>
        )}
        <span>Significant: <strong>{data.filter(p => p.fdr < 0.05).length.toLocaleString()}</strong></span>
        <span>w/ Output: <strong>{data.filter(p => p.has_output_data).length}</strong></span>
        <span>w/ Paper: <strong>{data.filter(p => p.has_report).length}</strong></span>
      </div>
    </div>
  );
};

function createHoverText(point) {
  const intervention = point.intervention || 'Unknown';
  const gseId = point.gse_id || 'N/A';
  const category = point.condition_category || 'Other';
  const log2fc = point.log2FoldChange?.toFixed(2) || 'N/A';
  const pvalue = point.pvalue?.toExponential(2) || 'N/A';
  const fdr = point.fdr?.toExponential(2) || 'N/A';
  const negLog10 = point.neg_log10_fdr?.toFixed(2) || 'N/A';
  const score = point.trust_score?.toFixed(0) || 'N/A';

  let text = `<b>${intervention}</b><br>GSE: ${gseId}<br>Category: ${category}<br><br>`;
  text += `Log2FC: ${log2fc}<br>P-value: ${pvalue}<br>`;
  text += `FDR: ${fdr}<br>-log10(FDR): ${negLog10}<br><br>Score: ${score}`;

  if (point.has_output_data || point.has_report) {
    text += '<br><br>Available:';
    if (point.has_output_data) text += '<br>✓ Output Data';
    if (point.has_report) text += '<br>✓ Mini Paper';
  }

  return text;
}

const styles = {
  plotContainer: {
    width: '100%',
    height: '100%',
    minHeight: '750px',
    display: 'flex',
    flexDirection: 'column',
    position: 'relative'
  },
  loading: {
    display: 'flex',
    flexDirection: 'column',
    justifyContent: 'center',
    alignItems: 'center',
    height: '750px',
    color: 'white',
    fontSize: '16px'
  },
  loadingSpinner: {
    width: '45px',
    height: '45px',
    border: '4px solid rgba(255, 255, 255, 0.08)',
    borderTop: '4px solid #B5BBA9',
    borderRadius: '50%',
    animation: 'spin 1s linear infinite',
    marginBottom: '18px'
  },
  loadingText: {
    fontSize: '14px',
    color: 'rgba(255, 255, 255, 0.65)'
  },
  empty: {
    display: 'flex',
    flexDirection: 'column',
    justifyContent: 'center',
    alignItems: 'center',
    height: '750px',
    color: 'white',
    textAlign: 'center'
  },
  emptyIcon: {
    fontSize: '56px',
    marginBottom: '16px',
    opacity: 0.4
  },
  emptyText: {
    fontSize: '16px',
    color: 'rgba(255, 255, 255, 0.65)'
  },
  stats: {
    marginTop: '8px',
    padding: '8px 12px',
    background: 'rgba(255, 255, 255, 0.04)',
    borderRadius: '5px',
    color: 'white',
    fontSize: '12px',
    display: 'flex',
    justifyContent: 'space-around',
    flexWrap: 'wrap',
    gap: '12px',
    borderTop: '1px solid rgba(255,255,255,0.08)'
  }
};

// Add keyframes for loading spinner
const styleSheet = document.styleSheets[0];
const keyframes = `
  @keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
  }
`;
if (styleSheet) {
  try {
    styleSheet.insertRule(keyframes, styleSheet.cssRules.length);
  } catch (e) {
    // Ignore if already exists
  }
}

export default VolcanoPlot;