import React, { useState, useEffect } from 'react';
import VolcanoPlot from './VolcanoPlot';
import InterventionsTable from './InterventionsTable';
import ReportViewer from './ReportViewer';
import FilterControls from './FilterControls';
import ResponsiveNav from './ResponsiveNav';
import Footer from './Footer';

const InterventionsView = () => {
  const [viewMode, setViewMode] = useState('table'); // 'table' or 'volcano'
  const [tableData, setTableData] = useState([]);
  const [volcanoData, setVolcanoData] = useState([]);
  const [selectedGseId, setSelectedGseId] = useState(null);
  const [selectedRowId, setSelectedRowId] = useState(null);
  const [filters, setFilters] = useState({
    categories: ['Genetic', 'Drug', 'Environment', 'Disease', 'Other'],
    minScore: 0,
    maxFdr: 1.0,
    minAbsEffect: 0,
    searchQuery: '',
    hasMiniPaper: false,
    hasScore: false
  });
  const [loading, setLoading] = useState(true);
  const [volcanoLoading, setVolcanoLoading] = useState(false);
  const [stats, setStats] = useState(null);
  const [volcanoDataLoaded, setVolcanoDataLoaded] = useState(false);
  const [pagination, setPagination] = useState({
    page: 1,
    page_size: 50,
    total_items: 0,
    total_pages: 0,
    has_next: false,
    has_prev: false
  });
  const [sortConfig, setSortConfig] = useState({ key: 'trust_score', order: 'desc' });

  // Load initial data for table
  useEffect(() => {
    loadTableData();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [filters.categories, pagination.page, sortConfig]);

  // Reload when filters change (including search) - reset to page 1
  useEffect(() => {
    setPagination(prev => ({ ...prev, page: 1 }));
    loadTableData();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [filters.minScore, filters.maxFdr, filters.minAbsEffect, filters.searchQuery, filters.hasMiniPaper, filters.hasScore]);

  useEffect(() => {
    const hash = window.location.hash.substring(1);
    if (hash) {
      setSelectedGseId(hash);
    }
  }, []);

  // Load volcano data when switching to volcano mode for the first time
  useEffect(() => {
    if (viewMode === 'volcano' && !volcanoDataLoaded) {
      loadVolcanoData();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [viewMode]);

  // Reload volcano data when filters change and we're in volcano mode
  useEffect(() => {
    if (viewMode === 'volcano' && volcanoDataLoaded) {
      loadVolcanoData();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [filters.categories, filters.minScore, filters.maxFdr, filters.minAbsEffect, filters.searchQuery, filters.hasMiniPaper, filters.hasScore]);

  const loadTableData = async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams();
      
      // Category filter
      if (filters.categories.length > 0 && filters.categories.length < 5) {
        filters.categories.forEach(cat => params.append('category', cat));
      }

      // Server-side filters
      if (filters.minScore > 0) {
        params.append('min_score', filters.minScore);
      }
      if (filters.maxFdr < 1.0) {
        params.append('max_fdr', filters.maxFdr);
      }
      if (filters.minAbsEffect > 0) {
        params.append('min_abs_effect', filters.minAbsEffect);
      }

      // Search filter - SEND TO SERVER
      if (filters.searchQuery && filters.searchQuery.trim()) {
        params.append('search', filters.searchQuery.trim());
      }

      // Mini Paper filter
      if (filters.hasMiniPaper) {
        params.append('has_report', 'true');
      }

      // Score filter
      if (filters.hasScore) {
        params.append('has_score', 'true');
      }

      // Pagination
      params.append('page', pagination.page);
      params.append('page_size', pagination.page_size);
      
      // Sorting
      params.append('sort_by', sortConfig.key);
      params.append('sort_order', sortConfig.order);

      const url = `/api/interventions/volcano-data?${params}`;
      
      const response = await fetch(url);
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      
      const result = await response.json();
      
      setTableData(result.data);
      
      if (result.metadata) {
        setStats({
          total: result.pagination?.total_items || result.metadata.total_comparisons,
          filtered: result.data.length,
          significant: result.metadata.significant_count,
          categoryCount: result.metadata.categories
        });
      }

      if (result.pagination) {
        setPagination(result.pagination);
      }
      
    } catch (error) {
      console.error('Error loading table data:', error);
      setTableData([]);
      setStats(null);
    } finally {
      setLoading(false);
    }
  };

  const loadVolcanoData = async () => {
    setVolcanoLoading(true);
    try {
      const params = new URLSearchParams();
      
      // For volcano, load ALL data (no pagination)
      params.append('page_size', 10000); // Large number to get all data
      
      // Category filter
      if (filters.categories.length > 0 && filters.categories.length < 5) {
        filters.categories.forEach(cat => params.append('category', cat));
      }

      // Filters
      if (filters.minScore > 0) {
        params.append('min_score', filters.minScore);
      }
      if (filters.maxFdr < 1.0) {
        params.append('max_fdr', filters.maxFdr);
      }
      if (filters.minAbsEffect > 0) {
        params.append('min_abs_effect', filters.minAbsEffect);
      }

      // Search filter - SEND TO SERVER
      if (filters.searchQuery && filters.searchQuery.trim()) {
        params.append('search', filters.searchQuery.trim());
      }

      // Mini Paper filter
      if (filters.hasMiniPaper) {
        params.append('has_report', 'true');
      }

      // Score filter
      if (filters.hasScore) {
        params.append('has_score', 'true');
      }

      const response = await fetch(`/api/interventions/volcano-data?${params}`);
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      
      const result = await response.json();
      
      setVolcanoData(result.data);
      setVolcanoDataLoaded(true);
      
    } catch (error) {
      console.error('Error loading volcano data:', error);
      setVolcanoData([]);
    } finally {
      setVolcanoLoading(false);
    }
  };

  const handlePointClick = (gseId, rowId = null) => {
    setSelectedGseId(gseId);
    setSelectedRowId(rowId);
    window.history.pushState({}, '', `#${gseId}`);
  };

  const handleCloseReport = () => {
    setSelectedGseId(null);
    setSelectedRowId(null);
    window.history.pushState({}, '', window.location.pathname);
  };

  const handleViewModeChange = (mode) => {
    setViewMode(mode);
    // Loading is handled by useEffect
  };

  const handlePageChange = (newPage) => {
    setPagination(prev => ({ ...prev, page: newPage }));
  };

  const handleSortChange = (key) => {
    setSortConfig(prev => ({
      key,
      order: prev.key === key && prev.order === 'desc' ? 'asc' : 'desc'
    }));
    setPagination(prev => ({ ...prev, page: 1 })); // Reset to first page on sort
  };

  return (
    <div style={styles.page}>
      <ResponsiveNav />
      
      <main style={styles.main}>
        <div style={styles.titleSection}>
          <h1 style={styles.title}>Aging Interventions</h1>
          <p style={styles.subtitle}>
            Interactive visualization of mouse RNA-seq aging interventions (~1M samples)
          </p>
        </div>

        <div style={styles.filtersSection}>
          <FilterControls 
            filters={filters} 
            onFilterChange={setFilters}
            stats={stats}
          />
        </div>

          {/* View Mode Toggle */}
          <div style={styles.viewModeSection}>
            <div style={styles.viewModeToggle}>
              <button
                style={{
                  ...styles.viewModeButton,
                  ...(viewMode === 'table' ? styles.viewModeButtonActive : {})
                }}
                onClick={() => handleViewModeChange('table')}
              >
                📊 Table View
              </button>
              <button
                style={{
                  ...styles.viewModeButton,
                  ...(viewMode === 'volcano' ? styles.viewModeButtonActive : {})
                }}
                onClick={() => handleViewModeChange('volcano')}
              >
                🌋 Volcano Plot
              </button>
          </div>
        </div>

        <div style={styles.contentSection}>
          <div style={styles.splitPanel}>
            <div style={styles.dataPanel}>
              <div style={styles.panelHeader}>
                <h2 style={styles.panelTitle}>
                  {viewMode === 'table' ? 'Data Table' : 'Volcano Plot'}
                </h2>
                {stats && viewMode === 'table' && (
                  <div style={styles.panelStats}>
                    Page {pagination.page} of {pagination.total_pages} ({pagination.total_items?.toLocaleString()} total)
                  </div>
                )}
                {stats && viewMode === 'volcano' && (
                  <div style={styles.panelStats}>
                    {volcanoData.length?.toLocaleString()} comparisons
                  </div>
                )}
              </div>
              <div style={styles.panelContent}>
                {viewMode === 'table' ? (
                  <div style={styles.tableContainer}>
                    <InterventionsTable
                      data={tableData}
                      onRowClick={handlePointClick}
                      selectedGseId={selectedGseId}
                      selectedRowId={selectedRowId}
                      loading={loading}
                      onSort={handleSortChange}
                      sortConfig={sortConfig}
                    />
                    
                    {/* Server-side pagination controls */}
                    {!loading && pagination.total_pages > 1 && (
                      <div style={styles.serverPagination}>
                        <div style={styles.paginationInfo}>
                          Page {pagination.page} of {pagination.total_pages} ({pagination.total_items?.toLocaleString()} total items)
                        </div>
                        <div style={styles.paginationControls}>
                          <button
                            style={{
                              ...styles.paginationButton,
                              ...(!pagination.has_prev ? styles.paginationButtonDisabled : {})
                            }}
                            onClick={() => handlePageChange(1)}
                            disabled={!pagination.has_prev}
                          >
                            ««
                          </button>
                          <button
                            style={{
                              ...styles.paginationButton,
                              ...(!pagination.has_prev ? styles.paginationButtonDisabled : {})
                            }}
                            onClick={() => handlePageChange(pagination.page - 1)}
                            disabled={!pagination.has_prev}
                          >
                            ‹
                          </button>
                          <span style={styles.pageNumber}>
                            {pagination.page} / {pagination.total_pages}
                          </span>
                          <button
                            style={{
                              ...styles.paginationButton,
                              ...(!pagination.has_next ? styles.paginationButtonDisabled : {})
                            }}
                            onClick={() => handlePageChange(pagination.page + 1)}
                            disabled={!pagination.has_next}
                          >
                            ›
                          </button>
                          <button
                            style={{
                              ...styles.paginationButton,
                              ...(!pagination.has_next ? styles.paginationButtonDisabled : {})
                            }}
                            onClick={() => handlePageChange(pagination.total_pages)}
                            disabled={!pagination.has_next}
                          >
                            »»
                          </button>
                        </div>
                      </div>
                    )}
                  </div>
                ) : (
                  <VolcanoPlot
                    data={volcanoData}
                    onPointClick={handlePointClick}
                    selectedGseId={selectedGseId}
                    loading={volcanoLoading}
                  />
                )}
              </div>
            </div>

            <div style={styles.reportPanel}>
              <div style={styles.panelHeader}>
                <h2 style={styles.panelTitle}>
                  {selectedGseId ? 'Reports' : 'Select a Point'}
                </h2>
              </div>
              <div style={styles.panelContent}>
                <ReportViewer 
                  gseId={selectedGseId}
                  onClose={handleCloseReport}
                />
              </div>
            </div>
          </div>
        </div>

        <div style={styles.helpSection}>
          <details style={styles.helpDetails}>
            <summary style={styles.helpSummary}>
              ℹ️ How to use
            </summary>
            <div style={styles.helpContent}>
              <p style={styles.helpText}>
                <strong>View Mode:</strong> Toggle between Table and Volcano Plot views.<br />
                <strong>Filter:</strong> Use controls above to narrow comparisons by category, score, FDR, or effect size.<br />
                <strong>Explore:</strong> {viewMode === 'table' ? 'Click any row' : 'Click any point'} to view detailed reports.<br />
                <strong>Search:</strong> Find specific GSE IDs or intervention names across ALL samples.<br />
                <strong>Sort (Table):</strong> Click column headers to sort data.<br />
                <strong>Navigate:</strong> Use pagination controls to browse through pages.
              </p>
            </div>
          </details>
        </div>
      </main>

      <Footer />
    </div>
  );
};

const styles = {
  page: {
    minHeight: '100vh',
    background: 'linear-gradient(150deg, #000000, #172554 60%, #94a3b8)',
    color: 'white',
    display: 'flex',
    flexDirection: 'column'
  },
  main: {
    flex: 1,
    maxWidth: '1920px',
    width: '100%',
    margin: '0 auto',
    padding: '16px 24px',
    display: 'flex',
    flexDirection: 'column',
    gap: '16px'
  },
  titleSection: {
    textAlign: 'center',
    padding: '12px 0'
  },
  title: {
    margin: 0,
    fontSize: '36px',
    fontWeight: 'bold',
    marginBottom: '6px',
    letterSpacing: '-0.5px'
  },
  subtitle: {
    margin: 0,
    fontSize: '15px',
    color: 'rgba(255, 255, 255, 0.65)',
    fontWeight: 'normal'
  },
  filtersSection: {
    width: '100%'
  },
  viewModeSection: {
    display: 'flex',
    justifyContent: 'center',
    alignItems: 'center',
    padding: '8px 0'
  },
  viewModeToggle: {
    display: 'flex',
    gap: '12px',
    background: 'rgba(255, 255, 255, 0.06)',
    padding: '6px',
    borderRadius: '10px',
    border: '1px solid rgba(255, 255, 255, 0.12)'
  },
  viewModeButton: {
    background: 'transparent',
    border: 'none',
    color: 'rgba(255, 255, 255, 0.6)',
    padding: '10px 24px',
    borderRadius: '6px',
    cursor: 'pointer',
    fontSize: '14px',
    fontWeight: '600',
    transition: 'all 0.2s',
    display: 'flex',
    alignItems: 'center',
    gap: '6px'
  },
  viewModeButtonActive: {
    background: 'rgba(181, 187, 169, 0.2)',
    color: '#B5BBA9',
    boxShadow: '0 2px 4px rgba(0, 0, 0, 0.2)'
  },
  contentSection: {
    flex: 1,
    minHeight: '900px'
  },
  splitPanel: {
    display: 'grid',
    gridTemplateColumns: '65% 35%',
    height: '100%',
    minHeight: '900px'
  },
  dataPanel: {
    background: 'rgba(255, 255, 255, 0.06)',
    borderRadius: '10px',
    border: '1px solid rgba(255, 255, 255, 0.12)',
    display: 'flex',
    flexDirection: 'column',
    overflow: 'hidden',
    boxShadow: '0 4px 6px rgba(0, 0, 0, 0.1)',
    marginRight: '20px'
  },
  reportPanel: {
    background: 'rgba(255, 255, 255, 0.06)',
    borderRadius: '10px',
    border: '1px solid rgba(255, 255, 255, 0.12)',
    display: 'flex',
    flexDirection: 'column',
    overflow: 'hidden',
    boxShadow: '0 4px 6px rgba(0, 0, 0, 0.1)'
  },
  panelHeader: {
    padding: '14px 20px',
    borderBottom: '1px solid rgba(255, 255, 255, 0.12)',
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    flexShrink: 0,
    background: 'rgba(255, 255, 255, 0.02)'
  },
  panelTitle: {
    margin: 0,
    fontSize: '17px',
    fontWeight: '600',
    letterSpacing: '-0.2px'
  },
  panelStats: {
    fontSize: '13px',
    color: 'rgba(255, 255, 255, 0.55)',
    fontWeight: '500'
  },
  panelContent: {
    flex: 1,
    overflow: 'auto',
    padding: '20px',
    display: 'flex',
    flexDirection: 'column'
  },
  tableContainer: {
    flex: 1,
    display: 'flex',
    flexDirection: 'column',
    gap: '16px'
  },
  serverPagination: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: '12px 16px',
    background: 'rgba(255, 255, 255, 0.04)',
    borderRadius: '6px',
    marginTop: 'auto',
    borderTop: '1px solid rgba(255, 255, 255, 0.08)'
  },
  paginationInfo: {
    fontSize: '13px',
    color: 'rgba(255, 255, 255, 0.6)'
  },
  paginationControls: {
    display: 'flex',
    gap: '8px',
    alignItems: 'center'
  },
  paginationButton: {
    background: 'rgba(255, 255, 255, 0.08)',
    border: '1px solid rgba(255, 255, 255, 0.15)',
    color: 'white',
    padding: '6px 12px',
    borderRadius: '4px',
    cursor: 'pointer',
    fontSize: '14px',
    transition: 'all 0.2s',
    fontWeight: '500'
  },
  paginationButtonDisabled: {
    opacity: 0.3,
    cursor: 'not-allowed'
  },
  pageNumber: {
    fontSize: '13px',
    color: 'rgba(255, 255, 255, 0.8)',
    fontWeight: '500',
    margin: '0 8px'
  },
  helpSection: {
    marginTop: '12px'
  },
  helpDetails: {
    background: 'rgba(255, 255, 255, 0.04)',
    borderRadius: '6px',
    border: '1px solid rgba(255, 255, 255, 0.08)',
    padding: '12px 16px'
  },
  helpSummary: {
    cursor: 'pointer',
    fontWeight: '600',
    fontSize: '14px',
    color: 'rgba(255, 255, 255, 0.85)',
    userSelect: 'none'
  },
  helpContent: {
    marginTop: '10px'
  },
  helpText: {
    margin: 0,
    fontSize: '13px',
    lineHeight: '1.6',
    color: 'rgba(255, 255, 255, 0.7)'
  }
};

export default InterventionsView;