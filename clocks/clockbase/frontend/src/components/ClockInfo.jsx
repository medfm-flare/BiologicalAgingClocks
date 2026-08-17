import { useState, useEffect } from 'react';
import { ChevronLeft, Search, ChevronUp, ChevronDown } from 'lucide-react';
import ParticlesBackground from './ParticlesBackground.jsx';
import ResponsiveNav from './ResponsiveNav.jsx';
import { useNavigate } from 'react-router-dom';

const ClockInfo = () => {
  const [clockData, setClockData] = useState([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState(null);
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage] = useState(10);
  const [searchTerm, setSearchTerm] = useState('');
  const [sortConfig, setSortConfig] = useState({ key: null, direction: 'asc' });

  const navigate = useNavigate();
  const handleBack = () => {
    navigate('/');
  };

  // Simulated data fetch function
  const fetchClockTable = async () => {
    setIsLoading(true);
    setError(null);
    try {
      // Replace with your actual API endpoint
      const response = await fetch(`https://${window.location.host}/api/clock-table`);
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }
      const result = await response.json();
      setClockData(result);
    } catch (err) {
      // For demo purposes, using mock data
      const mockData = [
        { Clock: "Horvath", Year: 2013, Species: "Human", Tissue: "Multi-tissue", Algorithm: "ElasticNet", "# of CpGs": 353, Description: "Original multi-tissue human clock, developed by aging clock pioneer Steve Horvath" },
        { Clock: "Hannum", Year: 2013, Species: "Human", Tissue: "Blood", Algorithm: "ElasticNet", "# of CpGs": 71, Description: "First large-scale human blood-based clock, developed by Greg Hannum, Justin Guinney and colleagues" },
        { Clock: "PhenoAge", Year: 2018, Species: "Human", Tissue: "Blood", Algorithm: "ElasticNet", "# of CpGs": 513, Description: "Blood-based human clock designed specifically to predict aging outcomes and mortality, developed by Morgan Levine and colleagues" },
        { Clock: "DunedinPoAm", Year: 2020, Species: "Human", Tissue: "Blood", Algorithm: "ElasticNet", "# of CpGs": 46, Description: "Blood-based human clock that computes the pace of aging, developed by Daniel Belsky and colleagues" },
      ];
      setClockData(mockData);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    fetchClockTable();
  }, []);

  // Filter data based on search term
  const filteredData = clockData.filter(item =>
    Object.values(item).some(value =>
      value.toString().toLowerCase().includes(searchTerm.toLowerCase())
    )
  );

  // Sort data based on sort configuration
  const sortedData = [...filteredData].sort((a, b) => {
    if (!sortConfig.key) return 0;
    
    let aValue = a[sortConfig.key];
    let bValue = b[sortConfig.key];
    
    // Handle numeric sorting for Year and # of CpGs
    if (sortConfig.key === 'Year' || sortConfig.key === '# of CpGs') {
      aValue = Number(aValue);
      bValue = Number(bValue);
    } else {
      // Handle string sorting
      aValue = aValue.toString().toLowerCase();
      bValue = bValue.toString().toLowerCase();
    }
    
    if (aValue < bValue) {
      return sortConfig.direction === 'asc' ? -1 : 1;
    }
    if (aValue > bValue) {
      return sortConfig.direction === 'asc' ? 1 : -1;
    }
    return 0;
  });


  // Pagination logic
  const totalItems = sortedData.length;
  const totalPages = Math.ceil(totalItems / itemsPerPage);
  const startIndex = (currentPage - 1) * itemsPerPage;
  const endIndex = startIndex + itemsPerPage;
  const currentItems = filteredData.slice(startIndex, endIndex);

  const goToPreviousPage = () => {
    if (currentPage > 1) {
      setCurrentPage(currentPage - 1);
    }
  };

  const goToNextPage = () => {
    if (currentPage < totalPages) {
      setCurrentPage(currentPage + 1);
    }
  };

  const handleSearchChange = (e) => {
    setSearchTerm(e.target.value);
    setCurrentPage(1); // Reset to first page when searching
  };

  const handleSort = (key) => {
    let direction = 'asc';
    if (sortConfig.key === key && sortConfig.direction === 'asc') {
      direction = 'desc';
    }
    setSortConfig({ key, direction });
    setCurrentPage(1); // Reset to first page when sorting
  };

  const getSortIcon = (columnKey) => {
    if (sortConfig.key !== columnKey) {
      return <ChevronUp className="w-4 h-4 text-gray-500" />;
    }
    return sortConfig.direction === 'asc' ? 
      <ChevronUp className="w-4 h-4 text-blue-400" /> : 
      <ChevronDown className="w-4 h-4 text-blue-400" />;
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-black via-blue-950 to-slate-900 text-white p-6">
      <ParticlesBackground />
      <ResponsiveNav />
      <div className="max-w-7xl mx-auto" style={{ position: 'relative', zIndex: 1, flex: 1, display: 'flex', flexDirection: 'column', }}>
        
        {/* Header */}
        <div className="flex items-center justify-between mb-8">
          <div className="flex items-center gap-4">
            <button className="p-2 hover:bg-gray-800 rounded-lg transition-colors">
              <ChevronLeft className="w-5 h-5" onClick={handleBack} />
            </button>
            <h1 className="text-2xl font-semibold">Clock Table</h1>
          </div>
          
          {/* Search */}
          <div className="relative">
            <input
              type="text"
              placeholder="Search..."
              value={searchTerm}
              onChange={handleSearchChange}
              className="bg-gray-800 border border-gray-700 rounded-lg px-4 py-2 pl-10 text-white placeholder-gray-400 focus:outline-none focus:border-blue-500"
            />
            <Search className="absolute left-3 top-2.5 w-4 h-4 text-gray-400" />
          </div>
        </div>

        {error && (
          <div className="mb-4 p-3 bg-red-900 text-red-200 rounded">
            Error: {error}
          </div>
        )}

        {/* Table */}
        <div className="bg-gray-900 rounded-lg border border-gray-800 overflow-hidden">
          <div>
            <table className="w-full">
              <thead className="bg-gray-800 border-b border-gray-700">
                <tr>
                  <th className="px-4 py-3 text-left text-sm font-medium text-gray-300">
                    <button
                      onClick={() => handleSort('Clock')}
                      className="flex items-center gap-1 hover:text-white transition-colors"
                    >
                      Clock
                      {getSortIcon('Clock')}
                    </button>
                  </th>
                  <th className="px-4 py-3 text-left text-sm font-medium text-gray-300">
                    <button
                      onClick={() => handleSort('Year')}
                      className="flex items-center gap-1 hover:text-white transition-colors"
                    >
                      Year
                      {getSortIcon('Year')}
                    </button>
                  </th>
                  <th className="px-4 py-3 text-left text-sm font-medium text-gray-300">
                    <button
                      onClick={() => handleSort('Species')}
                      className="flex items-center gap-1 hover:text-white transition-colors"
                    >
                      Species
                      {getSortIcon('Species')}
                    </button>
                  </th>
                  <th className="px-4 py-3 text-left text-sm font-medium text-gray-300">
                    <button
                      onClick={() => handleSort('Tissue')}
                      className="flex items-center gap-1 hover:text-white transition-colors"
                    >
                      Tissue
                      {getSortIcon('Tissue')}
                    </button>
                  </th>
                  <th className="px-4 py-3 text-left text-sm font-medium text-gray-300">
                    <button
                      onClick={() => handleSort('Algorithm')}
                      className="flex items-center gap-1 hover:text-white transition-colors"
                    >
                      Algorithm
                      {getSortIcon('Algorithm')}
                    </button>
                  </th>
                  <th className="px-4 py-3 text-left text-sm font-medium text-gray-300">
                    <button
                      onClick={() => handleSort('# of CpGs')}
                      className="flex items-center gap-1 hover:text-white transition-colors"
                    >
                      # of CpGs
                      {getSortIcon('# of CpGs')}
                    </button>
                  </th>
                  <th className="px-4 py-3 text-left text-sm font-medium text-gray-300">Description</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-800">
                {isLoading ? (
                  <tr>
                    <td colSpan="7" className="px-4 py-8 text-center text-gray-400">
                      Loading...
                    </td>
                  </tr>
                ) : currentItems.length ? (
                  currentItems.map((clock, index) => (
                    <tr
                      key={index}
                      className="hover:bg-gray-800 transition-colors even:bg-neutral-950 odd:bg-indigo-950/10"
                    >
                      <td className="px-4 py-4 text-sm">
                        <span className="text-blue-400 font-medium hover:underline cursor-pointer">
                          <a href={clock['Reference Link']}>{clock.Clock}</a>
                        </span>
                      </td>
                      <td className="px-4 py-4 text-sm text-gray-300">{clock.Year}</td>
                      <td className="px-4 py-4 text-sm text-gray-300">{clock.Species}</td>
                      <td className="px-4 py-4 text-sm text-gray-300">{clock.Tissue}</td>
                      <td className="px-4 py-4 text-sm text-gray-300">{clock.Algorithm}</td>
                      <td className="px-4 py-4 text-sm text-green-300 font-medium">{clock["# of CpGs"]}</td>
                      <td className="px-4 py-4 text-sm text-gray-300 max-w-md relative group">
                        <div className="truncate" title={clock.Description}>
                          {clock.Description}
                        </div>
                        <div className="absolute left-0 top-full mt-2 w-64 p-2 bg-gray-800 text-white text-sm rounded shadow-lg opacity-0 group-hover:opacity-100 transition-opacity duration-200 z-10">
                          {clock.Description}
                        </div>
                      </td>
                    </tr>
                  ))
                ) : (
                  <tr>
                    <td colSpan="7" className="px-4 py-8 text-center text-gray-400">
                      No clocks found
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>

          {/* Pagination */}
          {totalPages > 1 && (
            <div className="flex items-center justify-between px-4 py-3 bg-gray-800 border-t border-gray-700">
              <div className="text-sm text-gray-300">
                Showing {startIndex + 1} to {Math.min(endIndex, totalItems)} of {totalItems} entries
              </div>
              <div className="flex items-center gap-2">
                <button
                  onClick={goToPreviousPage}
                  disabled={currentPage === 1}
                  className="text-sm px-4 py-2 bg-gray-700 text-white rounded-lg hover:bg-gray-600 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                >
                  Previous
                </button>
                
                {/* Page numbers */}
                <div className="flex gap-1">
                  {[...Array(totalPages)].map((_, i) => (
                    <button
                      key={i + 1}
                      onClick={() => setCurrentPage(i + 1)}
                      className={`w-8 h-8 text-sm rounded transition-colors ${
                        currentPage === i + 1
                          ? 'bg-indigo-500 text-white'
                          : 'bg-gray-700 text-gray-300 hover:bg-gray-600'
                      }`}
                    >
                      {i + 1}
                    </button>
                  ))}
                </div>
                
                <button
                  onClick={goToNextPage}
                  disabled={currentPage === totalPages}
                  className="text-sm px-4 py-2 bg-gray-700 text-white rounded-lg hover:bg-gray-600 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                >
                  Next
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default ClockInfo;
