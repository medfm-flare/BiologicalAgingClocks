import { useState, useEffect, useMemo } from 'react';
import { ChevronLeft, ChevronDown, ArrowRight, AlertCircle, Loader2, ExternalLink } from 'lucide-react';
import { useNavigate, useLocation } from 'react-router-dom';
import Footer from './Footer.jsx';
import ParticlesBackground from './ParticlesBackground.jsx';
import ResponsiveNav from './ResponsiveNav.jsx';

// Standard metadata columns (not clock predictions)
const METADATA_COLUMNS = [
  'GSE',
  'sample_id',
  'GSM',
  'source_name',
  'title',
  'harmonized_sex',
  'harmonized_disease',
  'harmonized_age',
  'harmonized_specimen_part',
];

const Step2BiologicalAge = () => {
  const location = useLocation();
  const navigate = useNavigate();

  const selectedGSEStep1 = location.state?.selectedGSE || '';

  // State
  const [selectedGSE, setSelectedGSE] = useState(selectedGSEStep1);
  const [gseData, setGseData] = useState([]);
  const [clockNames, setClockNames] = useState([]);
  const [selectedClock, setSelectedClock] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState(null);
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage] = useState(25);

  // Load GSE data
  const fetchGseData = async (gse) => {
    if (!gse) return;

    setIsLoading(true);
    setError(null);

    try {
      const response = await fetch(`/api/gse/${gse}`);

      if (response.status === 404) {
        setError(`GSE "${gse}" not found in database`);
        setGseData([]);
        setClockNames([]);
        setSelectedClock('');
        return;
      }

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(errorText || `HTTP ${response.status}`);
      }

      const data = await response.json();

      if (!Array.isArray(data) || data.length === 0) {
        setError('No samples found in this dataset');
        setGseData([]);
        setClockNames([]);
        setSelectedClock('');
        return;
      }

      setGseData(data);
      setCurrentPage(1);

      // Extract clock names (columns not in METADATA_COLUMNS)
      const allColumns = Object.keys(data[0] || {});
      const clocks = allColumns.filter((col) => !METADATA_COLUMNS.includes(col));
      setClockNames(clocks);
      setSelectedClock(clocks[0] || '');
    } catch (err) {
      console.error('Error fetching GSE data:', err);
      setError(err.message || 'Failed to load GSE data');
      setGseData([]);
      setClockNames([]);
      setSelectedClock('');
    } finally {
      setIsLoading(false);
    }
  };

  // Load data on mount or when selectedGSEStep1 changes
  useEffect(() => {
    if (selectedGSEStep1) {
      setSelectedGSE(selectedGSEStep1);
      fetchGseData(selectedGSEStep1);
    }
  }, [selectedGSEStep1]);

  // Pagination
  const paginatedData = useMemo(() => {
    const startIdx = (currentPage - 1) * itemsPerPage;
    return gseData.slice(startIdx, startIdx + itemsPerPage);
  }, [gseData, currentPage, itemsPerPage]);

  const totalPages = Math.max(1, Math.ceil(gseData.length / itemsPerPage));

  // Navigation
  const handleBackToStep1 = () => {
    navigate('/analysis/step1');
  };

  const handleProceedToStep3 = () => {
    if (gseData.length === 0) return;

    // Transform data for Step 3
    const formattedData = {
      metadata: gseData.map((item) => {
        const clockPredictions = {};
        const metadata = {};

        Object.entries(item).forEach(([key, value]) => {
          if (METADATA_COLUMNS.includes(key)) {
            metadata[key] = value;
          } else {
            clockPredictions[key] = value;
          }
        });

        return {
          ...metadata,
          clock_predictions: clockPredictions,
        };
      }),
      clocks: clockNames,
      columns: Object.keys(gseData[0] || {}),
    };

    navigate('/analysis/step3', {
      state: {
        gseData: formattedData,
        selectedGSE,
      },
    });
  };

  // Formatters
  const formatNumber = (value) => {
    const num = parseFloat(value);
    return !isNaN(num) && isFinite(num) ? num.toFixed(2) : 'N/A';
  };

  const getSampleId = (sample) => {
    return sample.sample_id || sample.GSM || 'Unknown';
  };

  const getGeoLink = (sample) => {
    const sampleId = getSampleId(sample);
    return `https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=${sampleId}`;
  };

  return (
    <div
      className='min-h-screen text-white'
      style={{
        background: 'linear-gradient(150deg, #000000, rgb(13, 26, 50) 60%, rgb(40, 55, 75))',
        position: 'relative',
        overflow: 'hidden',
      }}
    >
      <ParticlesBackground />

      <div className='relative z-10 min-h-screen flex flex-col'>
        <ResponsiveNav />

        <div className='flex-1 p-6 lg:p-10'>
          <div className='max-w-7xl mx-auto'>
            {/* Header */}
            <div className='flex items-center gap-4 mb-8'>
              <button
                onClick={handleBackToStep1}
                className='p-2 hover:bg-gray-800/50 rounded-lg transition-colors'
                aria-label='Back to Step 1'
              >
                <ChevronLeft className='w-5 h-5' />
              </button>
              <div>
                <h1 className='text-3xl font-semibold'>Step 2: Biological Age of Samples</h1>
                <p className='text-gray-400 mt-1'>
                  View clock predictions and metadata for {selectedGSE || 'selected dataset'}
                </p>
              </div>
            </div>

            {/* Error Alert */}
            {error && (
              <div className='mb-6 p-4 bg-red-900/30 border border-red-700/50 rounded-lg flex items-start gap-3'>
                <AlertCircle className='w-5 h-5 mt-0.5 flex-shrink-0 text-red-400' />
                <div className='flex-1'>
                  <p className='font-medium text-red-200'>Error</p>
                  <p className='text-sm mt-1 text-red-300'>{error}</p>
                </div>
              </div>
            )}

            <div className='flex flex-col lg:flex-row gap-6'>
              {/* Sidebar */}
              <div
                className='w-full lg:w-80 bg-gray-900/50 backdrop-blur-sm rounded-lg border border-gray-800 p-6 space-y-6 lg:sticky lg:top-6'
                style={{ maxHeight: 'fit-content' }}
              >
                <div>
                  <h2 className='text-lg font-semibold mb-4'>Dataset Info</h2>

                  <div className='space-y-4'>
                    <div>
                      <label className='block text-sm font-medium text-gray-400 mb-2'>Selected GSE</label>
                      <div className='p-3 bg-gray-800 rounded-lg border border-gray-700'>
                        <p className='text-white font-mono'>{selectedGSE || 'None'}</p>
                      </div>
                    </div>

                    <div>
                      <label className='block text-sm font-medium text-gray-400 mb-2'>Total Samples</label>
                      <div className='p-3 bg-gray-800 rounded-lg border border-gray-700'>
                        <p className='text-white font-mono'>{gseData.length}</p>
                      </div>
                    </div>

                    <div>
                      <label className='block text-sm font-medium text-gray-400 mb-2'>Select Clock</label>
                      <div className='relative'>
                        <select
                          value={selectedClock}
                          onChange={(e) => setSelectedClock(e.target.value)}
                          disabled={isLoading || clockNames.length === 0}
                          className='w-full bg-gray-800 border border-gray-700 rounded-lg px-3 py-2.5 text-white focus:outline-none focus:border-blue-500 appearance-none disabled:opacity-50 disabled:cursor-not-allowed cursor-pointer'
                        >
                          {clockNames.length > 0 ? (
                            clockNames.map((clock) => (
                              <option key={clock} value={clock}>
                                {clock}
                              </option>
                            ))
                          ) : (
                            <option value=''>No clocks available</option>
                          )}
                        </select>
                        <ChevronDown className='absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 pointer-events-none' />
                      </div>
                    </div>
                  </div>
                </div>
              </div>

              {/* Main Content */}
              <div className='flex-1 min-w-0'>
                {isLoading ? (
                  <div className='flex items-center justify-center h-96 bg-gray-900/30 rounded-lg border border-gray-800'>
                    <div className='text-center'>
                      <Loader2 className='w-12 h-12 animate-spin text-indigo-500 mx-auto mb-4' />
                      <p className='text-gray-400'>Loading dataset...</p>
                    </div>
                  </div>
                ) : gseData.length === 0 ? (
                  <div className='flex items-center justify-center h-96 bg-gray-900/30 rounded-lg border border-gray-800 border-dashed'>
                    <p className='text-gray-500'>No data available</p>
                  </div>
                ) : (
                  <div className='bg-gray-900/50 backdrop-blur-sm rounded-lg border border-gray-800 overflow-hidden'>
                    {/* Table */}
                    <div className='overflow-x-auto'>
                      <table className='w-full'>
                        <thead className='bg-gray-800 sticky top-0'>
                          <tr>
                            <th className='px-4 py-3 text-left text-sm font-medium text-gray-300 whitespace-nowrap'>
                              Sample ID
                            </th>
                            <th className='px-4 py-3 text-left text-sm font-medium text-gray-300 whitespace-nowrap'>
                              Title
                            </th>
                            <th className='px-4 py-3 text-left text-sm font-medium text-gray-300 whitespace-nowrap'>
                              Tissue
                            </th>
                            <th className='px-4 py-3 text-left text-sm font-medium text-gray-300 whitespace-nowrap'>
                              Sex
                            </th>
                            <th className='px-4 py-3 text-left text-sm font-medium text-gray-300 whitespace-nowrap'>
                              Disease
                            </th>
                            <th className='px-4 py-3 text-left text-sm font-medium text-gray-300 whitespace-nowrap'>
                              Chronological Age
                            </th>
                            <th className='px-4 py-3 text-left text-sm font-medium text-gray-300 whitespace-nowrap'>
                              Specimen Part
                            </th>
                            {selectedClock && (
                              <th className='px-4 py-3 text-left text-sm font-medium text-green-400 whitespace-nowrap'>
                                {selectedClock}
                              </th>
                            )}
                          </tr>
                        </thead>
                        <tbody className='divide-y divide-gray-800'>
                          {paginatedData.map((sample, idx) => (
                            <tr key={getSampleId(sample) + idx} className='hover:bg-gray-800/50 transition-colors'>
                              <td className='px-4 py-3 text-sm'>
                                <a
                                  href={getGeoLink(sample)}
                                  target='_blank'
                                  rel='noopener noreferrer'
                                  className='text-blue-400 hover:text-blue-300 hover:underline inline-flex items-center gap-1'
                                >
                                  {getSampleId(sample)}
                                  <ExternalLink className='w-3 h-3' />
                                </a>
                              </td>
                              <td className='px-4 py-3 text-sm text-gray-300 max-w-xs truncate'>
                                {sample.title || sample.source_name || 'N/A'}
                              </td>
                              <td className='px-4 py-3 text-sm text-gray-300'>{sample.source_name || 'N/A'}</td>
                              <td className='px-4 py-3 text-sm text-gray-300'>{sample.harmonized_sex || 'N/A'}</td>
                              <td className='px-4 py-3 text-sm text-gray-300'>{sample.harmonized_disease || 'N/A'}</td>
                              <td className='px-4 py-3 text-sm text-gray-300'>{formatNumber(sample.harmonized_age)}</td>
                              <td className='px-4 py-3 text-sm text-gray-300'>
                                {sample.harmonized_specimen_part || 'N/A'}
                              </td>
                              {selectedClock && (
                                <td className='px-4 py-3 text-sm text-green-300 font-medium'>
                                  {formatNumber(sample[selectedClock])}
                                </td>
                              )}
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>

                    {/* Pagination */}
                    {totalPages > 1 && (
                      <div className='flex items-center justify-between px-6 py-4 bg-gray-800 border-t border-gray-700'>
                        <button
                          onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
                          disabled={currentPage === 1}
                          className='px-4 py-2 bg-gray-700 hover:bg-gray-600 text-white rounded-lg text-sm font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:bg-gray-700'
                        >
                          Previous
                        </button>
                        <span className='text-sm text-gray-300'>
                          Page {currentPage} of {totalPages} ({gseData.length} samples)
                        </span>
                        <button
                          onClick={() => setCurrentPage((p) => Math.min(totalPages, p + 1))}
                          disabled={currentPage === totalPages}
                          className='px-4 py-2 bg-gray-700 hover:bg-gray-600 text-white rounded-lg text-sm font-medium transition-colors disabled:opacity-50 disabled:cursor-not-allowed disabled:hover:bg-gray-700'
                        >
                          Next
                        </button>
                      </div>
                    )}
                  </div>
                )}
              </div>
            </div>

            {/* Bottom Actions */}
            <div className='flex justify-end mt-8'>
              <button
                onClick={handleProceedToStep3}
                disabled={gseData.length === 0 || isLoading}
                className={`flex items-center gap-2 px-6 py-3 rounded-lg font-medium transition-all ${
                  gseData.length > 0 && !isLoading
                    ? 'bg-blue-800 hover:bg-blue-900 text-white shadow-lg shadow-blue-900/20 border border-blue-700/50'
                    : 'bg-gray-700 text-gray-400 cursor-not-allowed'
                }`}
              >
                Proceed to Visualization
                <ArrowRight className='w-4 h-4' />
              </button>
            </div>
          </div>
        </div>

        <Footer />
      </div>
    </div>
  );
};

export default Step2BiologicalAge;
