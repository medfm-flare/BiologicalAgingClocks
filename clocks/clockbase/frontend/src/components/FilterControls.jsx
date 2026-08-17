import React, { useState, useEffect } from 'react';

const formatNumber = (num) => {
  if (num >= 1000000) {
    return (num / 1000000).toFixed(1).replace(/\.0$/, '') + 'M';
  }
  if (num >= 1000) {
    return (num / 1000).toFixed(1).replace(/\.0$/, '') + 'K';
  }
  return num.toString();
};

const FilterControls = ({ filters, onFilterChange, stats }) => {
  const FDR_MIN = 1e-6;
  const FDR_MAX = 1;

  const fdrFromSlider = (s) => {
    if (s <= 0) return 0;
    return FDR_MIN * Math.pow(FDR_MAX / FDR_MIN, s);
  };

  const sliderFromFdr = (fdr) => {
    if (!fdr || fdr <= 0) return 0;
    return Math.log(fdr / FDR_MIN) / Math.log(FDR_MAX / FDR_MIN);
  };

  const formatFdr = (x) => {
    if (x === 0) return '0';
    if (x >= 0.01) return x.toFixed(2);
    const [m, e] = x.toExponential(1).split('e');
    return `${m}e${e}`;
  };

  const [searchInput, setSearchInput] = useState(filters.searchQuery || '');
  const [isExpanded, setIsExpanded] = useState(true);
  const [fdrSlider, setFdrSlider] = useState(sliderFromFdr(filters.maxFdr ?? 0.05));

  const categories = ['Genetic', 'Drug', 'Environment', 'Disease', 'Other'];

  useEffect(() => {
    setSearchInput(filters.searchQuery || '');
  }, [filters.searchQuery]);

  const handleCategoryToggle = (category) => {
    const newCategories = filters.categories.includes(category)
      ? filters.categories.filter(c => c !== category)
      : [...filters.categories, category];
    
    onFilterChange({ ...filters, categories: newCategories });
  };

  const handleSelectAllCategories = () => {
    onFilterChange({ ...filters, categories: categories });
  };

  const handleDeselectAllCategories = () => {
    onFilterChange({ ...filters, categories: [] });
  };

  const handleScoreChange = (value) => {
    onFilterChange({ ...filters, minScore: parseInt(value) });
  };

  const handleFdrChange = (value) => {
    onFilterChange({ ...filters, maxFdr: parseFloat(value) });
  };

  const handleEffectChange = (value) => {
    onFilterChange({ ...filters, minAbsEffect: parseFloat(value) });
  };

  const handleSearchSubmit = () => {
    onFilterChange({ ...filters, searchQuery: searchInput.trim() });
  };

  const handleSearchClear = () => {
    setSearchInput('');
    onFilterChange({ ...filters, searchQuery: '' });
  };

  const handleResetFilters = () => {
    setSearchInput('');
    onFilterChange({
      categories: categories,
      minScore: 0,
      maxFdr: 1.0,
      minAbsEffect: 0,
      searchQuery: '',
      hasMiniPaper: false,
      hasScore: false
    });
  };

  const handleMiniPaperToggle = () => {
    const newValue = !filters.hasMiniPaper;
    onFilterChange({ ...filters, hasMiniPaper: newValue });
  };

  const handleScoreToggle = () => {
    const newValue = !filters.hasScore;

    onFilterChange({ ...filters, hasScore: newValue });
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

  const handleFdrSliderChange = (sRaw) => {
    const s = parseFloat(sRaw);
    const f = fdrFromSlider(s);
    setFdrSlider(s);
    handleFdrChange(f);
  };

  return (
    <div style={styles.container}>
      <div style={styles.header}>
        <div style={styles.headerLeft}>
          <h3 style={styles.title}>Filters</h3>
        </div>
        <div style={styles.headerButtons}>
          <button onClick={handleResetFilters} style={styles.resetButton}>
            Reset
          </button>
          <button 
            onClick={() => setIsExpanded(!isExpanded)} 
            style={styles.toggleButton}
          >
            {isExpanded ? '▼' : '▶'}
          </button>
        </div>
      </div>

      {isExpanded && (
        <div style={styles.content}>
          {/* First row: Search and filters */}
          <div style={styles.row}>
            <div style={styles.filterGroup}>
              <label style={styles.filterLabel}>🔍 Search</label>
              <div style={styles.searchContainer}>
                <input
                  type="text"
                  placeholder="GSE ID or intervention..."
                  value={searchInput}
                  onChange={(e) => setSearchInput(e.target.value)}
                  onKeyPress={(e) => e.key === 'Enter' && handleSearchSubmit()}
                  style={styles.searchInput}
                />
                {searchInput && (
                  <button onClick={handleSearchClear} style={styles.searchClear}>
                    ✕
                  </button>
                )}
                <button onClick={handleSearchSubmit} style={styles.searchButton}>
                  Go
                </button>
              </div>
            </div>

            <div style={styles.filterGroupCompact}>
              <label style={styles.filterLabel}>⭐ Score Available</label>
              <label style={styles.checkboxLabel}>
                <input
                  type="checkbox"
                  checked={filters.hasScore || false}
                  onChange={handleScoreToggle}
                  style={styles.checkbox}
                />
                <span style={styles.checkboxText}>Only with Score</span>
              </label>
            </div>

            <div style={styles.filterGroupCompact}>
              <label style={styles.filterLabel}>📄 Mini Paper</label>
              <label style={styles.checkboxLabel}>
                <input
                  type="checkbox"
                  checked={filters.hasMiniPaper || false}
                  onChange={handleMiniPaperToggle}
                  style={styles.checkbox}
                />
                <span style={styles.checkboxText}>Only with Mini Paper</span>
              </label>
            </div>
          </div>

          {/* Second row: Categories */}
          <div style={styles.row}>
            <div style={styles.filterGroup}>
              <div style={styles.filterLabelRow}>
                <label style={styles.filterLabel}>📊 Categories</label>
                <div style={styles.selectButtons}>
                  <button onClick={handleSelectAllCategories} style={styles.selectButton}>
                    All
                  </button>
                  <button onClick={handleDeselectAllCategories} style={styles.selectButton}>
                    None
                  </button>
                </div>
              </div>
              <div style={styles.categoryGrid}>
                {categories.map(category => {
                  const isSelected = filters.categories.includes(category);
                  const count = stats?.categoryCount?.[category] || 0;
                  
                  return (
                    <label 
                      key={category}
                      style={{
                        ...styles.categoryLabel,
                        ...(isSelected ? styles.categoryLabelSelected : {})
                      }}
                    >
                      <input
                        type="checkbox"
                        checked={isSelected}
                        onChange={() => handleCategoryToggle(category)}
                        style={styles.checkbox}
                      />
                      <span 
                        style={{
                          ...styles.categoryDot,
                          background: getCategoryColor(category)
                        }}
                      />
                      <span style={styles.categoryName}>{category}</span>
                      <span style={styles.categoryCount}>({formatNumber(count)})</span>
                    </label>
                  );
                })}
              </div>
            </div>
          </div>

          {/* Third row: Sliders in 3 columns */}
          <div style={styles.sliderRow}>
            {/* Score Filter */}
            <div style={styles.filterGroupSlider}>
              <label style={styles.filterLabel}>
                ⭐ Score ≥ <strong>{formatNumber(filters.minScore)}</strong>
              </label>

              <input
                type="range"
                min="0"
                max="150"
                step="10"
                value={filters.minScore}
                onChange={(e) => handleScoreChange(e.target.value)}
                style={styles.slider}
                aria-valuemin={0}
                aria-valuemax={150}
                aria-valuenow={filters.minScore}
              />

              <div style={styles.sliderLabels}>
                <span>0</span>
                <span>50</span>
                <span>100</span>
                <span>150</span>
              </div>
            </div>

            {/* FDR Filter */}
            <div style={styles.filterGroupSlider}>
              <label style={styles.filterLabel}>
                📈 FDR ≤ <strong>{formatFdr(filters.maxFdr)}</strong>
              </label>

              <input
                type="range"
                min="0"
                max="1"
                step="0.001"
                value={fdrSlider}
                onChange={(e) => handleFdrSliderChange(e.target.value)}
                style={styles.slider}
              />

              <div style={styles.sliderLabels}>
                <span>0</span>
                <span>1e-4</span>
                <span>0.05</span>
                <span>1.0</span>
              </div>
            </div>

            {/* Effect Size Filter */}
            <div style={styles.filterGroupSlider}>
              <label style={styles.filterLabel}>
                📏 |Effect| ≥ <strong>{filters.minAbsEffect}</strong>
              </label>
              <input
                type="range"
                min="0"
                max="10"
                step="0.5"
                value={filters.minAbsEffect}
                onChange={(e) => handleEffectChange(e.target.value)}
                style={styles.slider}
              />
              <div style={styles.sliderLabels}>
                <span>0</span>
                <span>2</span>
                <span>5</span>
                <span>10</span>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

const styles = {
  container: {
    background: 'rgba(255, 255, 255, 0.06)',
    borderRadius: '8px',
    border: '1px solid rgba(255, 255, 255, 0.12)',
    overflow: 'hidden'
  },
  header: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: '12px 16px',
    background: 'rgba(255, 255, 255, 0.03)',
    borderBottom: '1px solid rgba(255, 255, 255, 0.1)'
  },
  headerLeft: {
    display: 'flex',
    alignItems: 'baseline',
    gap: '10px'
  },
  title: {
    margin: 0,
    fontSize: '16px',
    fontWeight: '600',
    color: 'white',
    letterSpacing: '-0.2px'
  },
  statsText: {
    fontSize: '13px',
    fontWeight: 'normal',
    color: 'rgba(255, 255, 255, 0.5)'
  },
  headerButtons: {
    display: 'flex',
    gap: '8px'
  },
  resetButton: {
    background: 'rgba(231, 76, 60, 0.15)',
    border: '1px solid rgba(231, 76, 60, 0.3)',
    color: '#e74c3c',
    padding: '5px 10px',
    borderRadius: '4px',
    cursor: 'pointer',
    fontSize: '12px',
    fontWeight: '500',
    transition: 'all 0.2s'
  },
  toggleButton: {
    background: 'none',
    border: 'none',
    color: 'rgba(255, 255, 255, 0.7)',
    padding: '5px 8px',
    cursor: 'pointer',
    fontSize: '12px'
  },
  content: {
    padding: '16px',
    display: 'flex',
    flexDirection: 'column',
    gap: '16px'
  },
  row: {
    display: 'grid',
    gridTemplateColumns: '2fr 1fr 1fr',
    gap: '16px',
    alignItems: 'start'
  },
  sliderRow: {
    display: 'grid',
    gridTemplateColumns: 'repeat(3, 1fr)',
    gap: '16px',
    alignItems: 'start'
  },
  filterGroup: {
    display: 'flex',
    flexDirection: 'column',
    gap: '8px'
  },
  filterGroupCompact: {
    display: 'flex',
    flexDirection: 'column',
    gap: '8px',
    justifyContent: 'center'
  },
  filterGroupSlider: {
    display: 'flex',
    flexDirection: 'column',
    gap: '6px'
  },
  filterLabel: {
    color: 'white',
    fontSize: '11px',
    fontWeight: '500'
  },
  filterLabelRow: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center'
  },
  selectButtons: {
    display: 'flex',
    gap: '4px'
  },
  selectButton: {
    background: 'none',
    border: '1px solid rgba(255, 255, 255, 0.15)',
    color: 'rgba(255, 255, 255, 0.6)',
    padding: '3px 8px',
    borderRadius: '3px',
    cursor: 'pointer',
    fontSize: '10px',
    transition: 'all 0.2s'
  },
  searchContainer: {
    display: 'flex',
    gap: '6px',
    position: 'relative'
  },
  searchInput: {
    flex: 1,
    padding: '8px 10px',
    background: 'rgba(255, 255, 255, 0.05)',
    border: '1px solid rgba(255, 255, 255, 0.15)',
    borderRadius: '5px',
    color: 'white',
    fontSize: '13px',
    outline: 'none'
  },
  searchClear: {
    position: 'absolute',
    right: '4em',
    top: '50%',
    transform: 'translateY(-50%)',
    background: 'none',
    border: 'none',
    color: 'rgba(255, 255, 255, 0.4)',
    cursor: 'pointer',
    fontSize: '14px',
    padding: '0 8px'
  },
  searchButton: {
    background: 'rgba(181, 187, 169, 0.25)',
    border: '1px solid rgba(181, 187, 169, 0.4)',
    color: '#B5BBA9',
    padding: '8px 14px',
    borderRadius: '5px',
    cursor: 'pointer',
    fontSize: '13px',
    fontWeight: '500',
    transition: 'all 0.2s',
    whiteSpace: 'nowrap'
  },
  checkboxLabel: {
    display: 'flex',
    alignItems: 'center',
    gap: '8px',
    padding: '8px 10px',
    background: 'rgba(255, 255, 255, 0.03)',
    border: '1px solid rgba(255, 255, 255, 0.08)',
    borderRadius: '5px',
    cursor: 'pointer',
    transition: 'all 0.2s',
    fontSize: '12px',
    color: 'white'
  },
  checkboxText: {
    fontSize: '13px'
  },
  categoryGrid: {
    display: 'grid',
    gridTemplateColumns: 'repeat(auto-fit, minmax(110px, 1fr))',
    gap: '6px'
  },
  categoryLabel: {
    display: 'flex',
    alignItems: 'center',
    gap: '6px',
    padding: '8px 10px',
    background: 'rgba(255, 255, 255, 0.03)',
    border: '1px solid rgba(255, 255, 255, 0.08)',
    borderRadius: '5px',
    cursor: 'pointer',
    transition: 'all 0.2s',
    fontSize: '10px'
  },
  categoryLabelSelected: {
    background: 'rgba(255, 255, 255, 0.08)',
    borderColor: 'rgba(255, 255, 255, 0.25)'
  },
  checkbox: {
    cursor: 'pointer',
    width: '14px',
    height: '14px'
  },
  categoryDot: {
    width: '8px',
    height: '8px',
    borderRadius: '50%',
    flexShrink: 0
  },
  categoryName: {
    color: 'white',
    fontSize: '12px'
  },
  categoryCount: {
    color: 'rgba(255, 255, 255, 0.4)',
    fontSize: '11px',
    marginLeft: 'auto'
  },
  slider: {
    width: '100%',
    cursor: 'pointer',
    height: '4px'
  },
  sliderLabels: {
    display: 'flex',
    justifyContent: 'space-between',
    fontSize: '9px',
    color: 'rgba(255, 255, 255, 0.4)',
    marginTop: '-3px'
  }
};

export default FilterControls;