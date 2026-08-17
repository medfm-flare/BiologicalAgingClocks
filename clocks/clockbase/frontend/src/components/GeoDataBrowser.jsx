import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { Search, ChevronLeft, ChevronRight, ArrowRight, Filter } from 'lucide-react';

const GeoDataBrowser = ({ onProceedToStep2 }) => {
  const [data, setData] = useState([]);
  const [loading, setLoading] = useState(false);
  const [currentPage, setCurrentPage] = useState(1);
  const [searchQuery, setSearchQuery] = useState('');
  const [sortConfig, setSortConfig] = useState({ key: null, direction: 'asc' });
  const [totalEntries, setTotalEntries] = useState(0);
  const [selectedGSE, setSelectedGSE] = useState('');
  const [typeFilter, setTypeFilter] = useState(new Set());
  const [organismFilter, setOrganismFilter] = useState(new Set());
  const [filterOpen, setFilterOpen] = useState({ type: false, organism: false });
  const [uniqueTypes, setUniqueTypes] = useState([]);
  const [uniqueOrganisms, setUniqueOrganisms] = useState([]);
  const itemsPerPage = 5;

  const navigate = useNavigate();

  const columns = [
    {
      key: 'title',
      label: 'Title',
      sortable: true,
      width: 'w-[20%]',
      render: (value) => <div className="overflow-hidden text-ellipsis">{value}</div>,
    },
    {
      key: 'accession',
      label: 'GSE',
      sortable: true,
      width: 'w-[10%]',
      cellClass: 'text-blue-400',
      render: (value) => (
        <a className="hover:underline" href={`https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=${value}`}>
          {value}
        </a>
      ),
    },
    {
      key: 'samples',
      label: 'Samples',
      sortable: true,
      width: 'w-[8%]',
      cellClass: 'text-center',
      render: (value) => // As integer
        <div className="truncate">{parseInt(value, 10).toLocaleString()}</div>,
    },
    {
      key: 'description',
      label: 'Description',
      sortable: true,
      width: 'w-[35%]',
      cellClass: 'max-w-md relative group',
      render: (value) => (
        <div className="truncate" title={value}>
          {value}
        </div>
      ),
    },
    {
      key: 'type',
      label: 'Type',
      sortable: true,
      width: 'w-[12%]',
      filterable: true,
      render: (value) => <div className="truncate">{value}</div>,
    },
    {
      key: 'organism',
      label: 'Organism',
      sortable: true,
      width: 'w-[15%]',
      filterable: true,
      render: (value) => <div className="truncate">{value}</div>,
    },
  ];

  // Fetch filters from backend
  useEffect(() => {
    const fetchFilters = async () => {
      try {
        const response = await fetch('/api/geo-filters');
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }
        const result = await response.json();
        setUniqueTypes(result.types || []);
        setUniqueOrganisms(result.organisms || []);
      } catch (error) {
        console.error('Error fetching filters:', error);
      }
    };
    fetchFilters();
  }, []);

  // Fetch paginated data from backend
  const fetchData = async () => {
    setLoading(true);
    const params = new URLSearchParams({
      page: currentPage.toString(),
      size: itemsPerPage.toString(),
    });
    if (searchQuery) {
      params.append('search', searchQuery);
    }
    if (sortConfig.key) {
      params.append('sort_key', sortConfig.key);
      params.append('sort_direction', sortConfig.direction);
    }
    if (typeFilter.size > 0) {
      [...typeFilter].forEach((t) => params.append('types', t));
    }
    if (organismFilter.size > 0) {
      [...organismFilter].forEach((o) => params.append('organisms', o));
    }

    try {
      const response = await fetch(`/api/geo-metadata?${params.toString()}`);
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      const result = await response.json();
      setData(result.metadata || []);
      setTotalEntries(result.total || 0);
    } catch (error) {
      console.error('Error fetching data:', error);
      setData([]);
      setTotalEntries(0);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, [currentPage, searchQuery, sortConfig, typeFilter, organismFilter]);

  // Create empty rows to fix table height
  const getTableRows = () => {
    const emptyRowsCount = itemsPerPage - data.length;
    const rows = [...data];

    // Add empty rows to fix height
    for (let i = 0; i < emptyRowsCount; i++) {
      rows.push({ id: `empty-${i}`, isEmpty: true });
    }

    return rows;
  };

  const handleSort = (key) => {
    let direction = 'asc';
    if (sortConfig.key === key && sortConfig.direction === 'asc') {
      direction = 'desc';
    }
    setSortConfig({ key, direction });
    setCurrentPage(1);
  };

  const handleSearch = (e) => {
    setSearchQuery(e.target.value);
    setCurrentPage(1);
  };

  const handleDatasetSelection = (accession) => {
    if (accession === selectedGSE) {
      setSelectedGSE('');
    } else {
      setSelectedGSE(accession);
    }
  };

  const handleProceedToStep2 = () => {
    if (selectedGSE) {
      navigate('/analysis/step2', { state: { selectedGSE } });
    }
  };

  const handleTypeFilterChange = (value) => {
    const newFilter = new Set(typeFilter);
    if (newFilter.has(value)) {
      newFilter.delete(value);
    } else {
      newFilter.add(value);
    }
    setTypeFilter(newFilter);
    setCurrentPage(1);
  };

  const handleOrganismFilterChange = (value) => {
    const newFilter = new Set(organismFilter);
    if (newFilter.has(value)) {
      newFilter.delete(value);
    } else {
      newFilter.add(value);
    }
    setOrganismFilter(newFilter);
    setCurrentPage(1);
  };

  const toggleFilter = (column) => {
    setFilterOpen((prev) => ({
      ...prev,
      [column]: !prev[column],
    }));
  };

  const getFilterValues = (key) => {
    if (key === 'type') return uniqueTypes;
    if (key === 'organism') return uniqueOrganisms;
    return [];
  };

  const getFilterState = (key) => {
    if (key === 'type') return typeFilter;
    if (key === 'organism') return organismFilter;
    return new Set();
  };

  const getOnFilterChange = (key) => {
    if (key === 'type') return handleTypeFilterChange;
    if (key === 'organism') return handleOrganismFilterChange;
    return () => {};
  };

  const getIsFilterOpen = (key) => {
    return filterOpen[key] || false;
  };

  const totalPages = Math.ceil(totalEntries / itemsPerPage);
  const startEntry = (currentPage - 1) * itemsPerPage + 1;
  const endEntry = Math.min(currentPage * itemsPerPage, totalEntries);

  const getPageNumbers = () => {
    const pages = [];
    const maxVisible = 5;

    if (totalPages <= maxVisible) {
      for (let i = 1; i <= totalPages; i++) {
        pages.push(i);
      }
    } else {
      if (currentPage <= 3) {
        pages.push(1, 2, 3, 4, '...', totalPages);
      } else if (currentPage >= totalPages - 2) {
        pages.push(1, '...', totalPages - 3, totalPages - 2, totalPages - 1, totalPages);
      } else {
        pages.push(1, '...', currentPage - 1, currentPage, currentPage + 1, '...', totalPages);
      }
    }

    return pages;
  };

  const SortableHeader = ({ children, sortKey, filterColumn, filterValues, onFilterChange, filterState, isFilterOpen, colWidth }) => (
    <th className={`px-2 py-2 text-left text-xs font-medium text-gray-300 relative ${colWidth || ''}`}>
      <div className="flex items-center gap-1 justify-center">
        <span
          className="cursor-pointer hover:text-white transition-colors"
          onClick={() => handleSort(sortKey)}
        >
          {children}
          {sortConfig.key === sortKey && (
            <span className="text-blue-400">
              {sortConfig.direction === 'asc' ? '↑' : '↓'}
            </span>
          )}
        </span>
        {filterColumn && (
          <div className="relative">
            <button
              onClick={() => toggleFilter(filterColumn)}
              className="p-1 hover:bg-gray-700 rounded"
            >
              <Filter className="w-3 h-3 text-gray-400" />
            </button>
            {isFilterOpen && (
              <div className="absolute z-50 bg-gray-800 border border-gray-600 rounded-md p-3 w-40 mt-1 shadow-xl">
                <div className="max-h-40 overflow-y-auto">
                  {filterValues.map((value) => (
                    <label key={value} className="flex items-center gap-1 text-xs text-gray-300 hover:bg-gray-700 px-1 py-1 rounded">
                      <input
                        type="checkbox"
                        checked={filterState.has(value)}
                        onChange={() => onFilterChange(value)}
                        className="w-3 h-3 text-blue-600 bg-gray-700 border-gray-600 rounded focus:ring-blue-500"
                      />
                      {value}
                    </label>
                  ))}
                </div>
              </div>
            )}
          </div>
        )}
      </div>
    </th>
  );

  return (
    <div className="text-white p-1">
      <div className="max-w-7xl mx-auto relative">
        <div className="flex items-center justify-between mb-6">
          <h1 className="text-xl font-semibold">
            Step 1: Find The GEO Data You Want to Analyze
          </h1>
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
            <input
              type="text"
              placeholder="GSE100849, Alzheimer, etc."
              value={searchQuery}
              onChange={handleSearch}
              className="bg-gray-800 border border-gray-700 rounded-lg pl-9 pr-3 py-1 w-72 text-sm text-white placeholder-gray-400 focus:outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500"
            />
          </div>
        </div>

        <div className="bg-gray-900 rounded-lg border border-gray-800 overflow-visible">
          {loading && (
            <div className="absolute inset-0 flex items-center justify-center z-10">
              <div className="text-white">Loading...</div>
            </div>
          )}
          <div className="overflow-x-auto">
            <table className="w-full table-auto">
              <thead className="bg-gray-800 border-b border-gray-700">
                <tr>
                  <th className="px-2 py-2 w-10"></th>
                  {columns.map((col) => (
                    <SortableHeader
                      key={col.key}
                      sortKey={col.key}
                      filterColumn={col.filterable ? col.key : undefined}
                      filterValues={getFilterValues(col.key)}
                      onFilterChange={getOnFilterChange(col.key)}
                      filterState={getFilterState(col.key)}
                      isFilterOpen={getIsFilterOpen(col.key)}
                      colWidth={col.width}
                    >
                      {col.label}
                    </SortableHeader>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-900">
                {getTableRows().map((item) => (
                  <tr
                    key={item.accession || item.id}
                    className={`transition-colors ${
                      item.isEmpty
                        ? 'h-12' // Reduced height for denser rows
                        : `hover:bg-gray-800 ${
                            selectedGSE === item.accession
                              ? 'bg-grey-950 border-2 border-solid border-indigo-500'
                              : 'odd:bg-neutral-950/50 even:bg-indigo-950/10'
                          }`
                    }`}
                    style={{ height: '48px' }} // Reduced fixed height
                  >
                    {item.isEmpty ? (
                      <>
                        <td className="px-2 py-2"></td>
                        {columns.map((col, idx) => (
                          <td key={idx} className="px-2 py-2"></td>
                        ))}
                      </>
                    ) : (
                      <>
                        <td className="px-2 py-2">
                          <input
                            type="checkbox"
                            checked={selectedGSE === item.accession}
                            onChange={() => handleDatasetSelection(item.accession)}
                            disabled={selectedGSE && selectedGSE !== item.accession}
                            className="w-3 h-3 text-blue-600 bg-gray-700 border-gray-600 rounded focus:ring-blue-500 focus:ring-2"
                          />
                        </td>
                        {columns.map((col) => (
                          <td
                            key={col.key}
                            className={`px-2 py-2 text-xs text-gray-300 ${col.cellClass || ''} ${col.width || ''}`}
                          >
                            {col.render ? col.render(item[col.key]) : <div className="truncate">{item[col.key]}</div>}
                          </td>
                        ))}
                      </>
                    )}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>

        <div className="flex items-center justify-between mt-4 py-3 px-3 rounded-lg bottom-0 z-10">
          <div className="text-xs text-gray-400">
            Showing {totalEntries > 0 ? startEntry : 0} to {endEntry} of {totalEntries.toLocaleString()} entries
          </div>
          <div className="flex items-center gap-2">
            <div className="flex items-center gap-1">
              <button
                onClick={() => setCurrentPage(Math.max(1, currentPage - 1))}
                disabled={currentPage === 1}
                className="p-1 rounded border border-gray-600 hover:bg-gray-800 disabled:cursor-not-allowed"
              >
                <ChevronLeft className="w-4 h-4" />
              </button>
              {getPageNumbers().map((page, index) => (
                <button
                  key={index}
                  onClick={() => typeof page === 'number' && setCurrentPage(page)}
                  disabled={page === '...'}
                  className={`px-3 py-1 rounded border border-gray-600 text-xs ${
                    page === currentPage
                      ? 'bg-indigo-950 hover:bg-indigo-900 text-white'
                      : page === '...'
                      ? 'cursor-default'
                      : 'hover:bg-indigo-950'
                  }`}
                >
                  {page}
                </button>
              ))}
              <button
                onClick={() => setCurrentPage(Math.min(totalPages, currentPage + 1))}
                disabled={currentPage === totalPages}
                className="p-1 rounded border border-gray-600 hover:bg-gray-800 disabled:cursor-not-allowed"
              >
                <ChevronRight className="w-4 h-4" />
              </button>
            </div>
            <button
              onClick={handleProceedToStep2}
              disabled={!selectedGSE}
              className={`flex items-center gap-2 px-4 py-1 rounded text-xs font-medium transition-colors ${
                selectedGSE
                  ? 'bg-indigo-900 hover:bg-indigo-500 text-white'
                  : 'bg-gray-700 text-gray-400 cursor-not-allowed'
              }`}
            >
              Proceed to Next Step
              <ArrowRight className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default GeoDataBrowser;