import React from 'react';

const InterventionsTable = ({ data, onRowClick, selectedGseId, loading, selectedRowId, onSort, sortConfig }) => {
  const handleSort = (key) => {
    if (onSort) {
      onSort(key);
    }
  };

  const getCategoryIcon = (category) => {
    const icons = {
      'Genetic': '🔵',
      'Drug': '💎',
      'Environment': '🟠',
      'Disease': '🔺',
      'Other': '✖️'
    };
    return icons[category] || '⚪';
  };

  const getCategoryColor = (category) => {
    const colors = {
      'Genetic': '#3498db',
      'Drug': '#9b59b6',
      'Environment': '#e67e22',
      'Disease': '#e74c3c',
      'Other': '#95a5a6'
    };
    return colors[category] || '#95a5a6';
  };

  const SortIcon = ({ column }) => {
    if (!sortConfig || sortConfig.key !== column) {
      return <span style={styles.sortIconInactive}>⇅</span>;
    }
    return <span style={styles.sortIconActive}>
      {sortConfig.order === 'asc' ? '↑' : '↓'}
    </span>;
  };

  if (loading) {
    return (
      <div style={styles.loading}>
        <div style={styles.loadingSpinner}></div>
        <div style={styles.loadingText}>Loading data...</div>
      </div>
    );
  }

  if (!data || data.length === 0) {
    return (
      <div style={styles.empty}>
        <div style={styles.emptyIcon}>📋</div>
        <div style={styles.emptyText}>No data available. Adjust filters to see results.</div>
      </div>
    );
  }

  return (
    <div style={styles.container}>
      <div style={styles.tableWrapper}>
        <table style={styles.table}>
          <thead style={styles.thead}>
            <tr>
              <th style={styles.th} onClick={() => handleSort('gse_id')}>
                GSE ID <SortIcon column="gse_id" />
              </th>
              <th style={styles.th} onClick={() => handleSort('intervention')}>
                Intervention <SortIcon column="intervention" />
              </th>
              <th style={styles.th} onClick={() => handleSort('condition_category')}>
                Category <SortIcon column="condition_category" />
              </th>
              <th style={{...styles.th, ...styles.thNumber}} onClick={() => handleSort('trust_score')}>
                Score <SortIcon column="trust_score" />
              </th>
              <th style={{...styles.th, ...styles.thNumber}} onClick={() => handleSort('log2FoldChange')}>
                Effect Size <SortIcon column="log2FoldChange" />
              </th>
              <th style={{...styles.th, ...styles.thNumber}} onClick={() => handleSort('fdr')}>
                FDR <SortIcon column="fdr" />
              </th>
              <th style={{...styles.th, ...styles.thNumber}} onClick={() => handleSort('neg_log10_fdr')}>
                -log10(FDR) <SortIcon column="neg_log10_fdr" />
              </th>
              <th style={styles.th}>
                Reports
              </th>
            </tr>
          </thead>
          <tbody style={styles.tbody}>
            {data.map((row, index) => {
              const isSelected = row.row_id === selectedRowId;
              return (
                <tr
                  key={row.row_id || `${row.gse_id}-${index}`}
                  style={{
                    ...styles.tr,
                    ...(isSelected ? styles.trSelected : {}),
                    ...(index % 2 === 0 ? styles.trEven : {})
                  }}
                  onClick={() => onRowClick(row.gse_id, row.row_id)}
                >
                  <td style={styles.td}>
                    <span style={styles.gseId}>{row.gse_id || 'N/A'}</span>
                  </td>
                  <td style={styles.td}>
                    <span style={styles.intervention}>{row.intervention || row.condition_name || 'Unknown'}</span>
                  </td>
                  <td style={styles.td}>
                    <span style={{
                      ...styles.categoryBadge,
                      background: `${getCategoryColor(row.condition_category)}20`,
                      color: getCategoryColor(row.condition_category),
                      border: `1px solid ${getCategoryColor(row.condition_category)}40`
                    }}>
                      {getCategoryIcon(row.condition_category)} {row.condition_category || 'Other'}
                    </span>
                  </td>
                  <td style={{...styles.td, ...styles.tdNumber}}>
                    <span style={styles.score}>{row.trust_score}</span>
                  </td>
                  <td style={{...styles.td, ...styles.tdNumber}}>
                    <span style={{
                      ...styles.effectSize,
                      color: row.log2FoldChange > 0 ? '#27ae60' : row.log2FoldChange < 0 ? '#e74c3c' : 'white'
                    }}>
                      {row.log2FoldChange?.toFixed(2) || 'N/A'}
                    </span>
                  </td>
                  <td style={{...styles.td, ...styles.tdNumber}}>
                    <span style={styles.fdr}>
                      {row.fdr ? row.fdr.toExponential(2) : 'N/A'}
                    </span>
                  </td>
                  <td style={{...styles.td, ...styles.tdNumber}}>
                    <span style={styles.negLog10}>
                      {row.neg_log10_fdr?.toFixed(2) || 'N/A'}
                    </span>
                  </td>
                  <td style={styles.td}>
                    <div style={styles.reportIcons}>
                      {row.has_output_data && (
                        <span style={styles.reportIcon} title="Output Data">📊</span>
                      )}
                      {row.has_report && (
                        <span style={styles.reportIcon} title="Mini Paper">📄</span>
                      )}
                      {!row.has_output_data && !row.has_report && (
                        <span style={styles.reportIconNone}>—</span>
                      )}
                    </div>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
};

const styles = {
  container: {
    display: 'flex',
    flexDirection: 'column',
    height: '100%',
    width: '100%'
  },
  tableWrapper: {
    flex: 1,
    overflowX: 'auto',
    overflowY: 'auto',
    background: 'rgba(0, 0, 0, 0.2)',
    borderRadius: '6px'
  },
  table: {
    width: '100%',
    borderCollapse: 'collapse',
    fontSize: '13px'
  },
  thead: {
    position: 'sticky',
    top: 0,
    background: 'rgba(0, 0, 0, 0.8)',
    zIndex: 10,
    backdropFilter: 'blur(10px)'
  },
  th: {
    padding: '12px 16px',
    textAlign: 'left',
    fontWeight: '600',
    color: 'rgba(255, 255, 255, 0.9)',
    borderBottom: '2px solid rgba(255, 255, 255, 0.2)',
    cursor: 'pointer',
    userSelect: 'none',
    whiteSpace: 'nowrap',
    transition: 'background 0.2s'
  },
  thNumber: {
    textAlign: 'right'
  },
  tbody: {
    background: 'transparent'
  },
  tr: {
    cursor: 'pointer',
    transition: 'all 0.15s',
    borderBottom: '1px solid rgba(255, 255, 255, 0.05)'
  },
  trEven: {
    background: 'rgba(255, 255, 255, 0.02)'
  },
  trSelected: {
    background: 'rgba(255, 215, 0, 0.15)',
    borderLeft: '3px solid #FFD700'
  },
  td: {
    padding: '10px 16px',
    color: 'rgba(255, 255, 255, 0.85)',
    verticalAlign: 'middle'
  },
  tdNumber: {
    textAlign: 'right',
    fontFamily: 'Monaco, Consolas, monospace'
  },
  gseId: {
    fontFamily: 'Monaco, Consolas, monospace',
    fontSize: '12px',
    color: '#3498db'
  },
  intervention: {
    fontWeight: '500',
    display: 'block',
    maxWidth: '300px',
    overflow: 'hidden',
    textOverflow: 'ellipsis',
    whiteSpace: 'nowrap'
  },
  categoryBadge: {
    display: 'inline-block',
    padding: '4px 10px',
    borderRadius: '12px',
    fontSize: '11px',
    fontWeight: '600',
    whiteSpace: 'nowrap'
  },
  score: {
    fontWeight: '600',
    color: '#B5BBA9'
  },
  effectSize: {
    fontWeight: '600'
  },
  fdr: {
    fontSize: '12px',
    color: 'rgba(255, 255, 255, 0.7)'
  },
  negLog10: {
    fontWeight: '500',
    color: 'rgba(255, 255, 255, 0.8)'
  },
  reportIcons: {
    display: 'flex',
    gap: '6px',
    justifyContent: 'center'
  },
  reportIcon: {
    fontSize: '16px',
    cursor: 'pointer'
  },
  reportIconNone: {
    fontSize: '14px',
    color: 'rgba(255, 255, 255, 0.2)'
  },
  sortIconInactive: {
    marginLeft: '4px',
    color: 'rgba(255, 255, 255, 0.3)',
    fontSize: '12px'
  },
  sortIconActive: {
    marginLeft: '4px',
    color: '#B5BBA9',
    fontSize: '12px',
    fontWeight: 'bold'
  },
  loading: {
    display: 'flex',
    flexDirection: 'column',
    justifyContent: 'center',
    alignItems: 'center',
    height: '400px',
    color: 'white'
  },
  loadingSpinner: {
    width: '40px',
    height: '40px',
    border: '4px solid rgba(255, 255, 255, 0.08)',
    borderTop: '4px solid #B5BBA9',
    borderRadius: '50%',
    animation: 'spin 1s linear infinite',
    marginBottom: '16px'
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
    height: '400px',
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

export default InterventionsTable;