import { useState, useEffect } from 'react';
import { ChevronLeft, ArrowLeft, AlertCircle, Download, Loader2 } from 'lucide-react';
import { useNavigate, useLocation } from 'react-router-dom';
import Footer from './Footer.jsx';
import ParticlesBackground from './ParticlesBackground.jsx';
import ResponsiveNav from './ResponsiveNav.jsx';

const Step3Visualization = () => {
  const location = useLocation();
  const navigate = useNavigate();
  const gseData = location.state?.gseData || { metadata: [], clocks: [], columns: [] };
  const selectedGSE = location.state?.selectedGSE;

  const [analysisType, setAnalysisType] = useState('');
  const [xAxis, setXAxis] = useState('');
  const [yAxis, setYAxis] = useState('');
  const [subgroupVariable, setSubgroupVariable] = useState('');
  const [imageSrc, setImageSrc] = useState(null);
  const [tableData, setTableData] = useState(null);
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(false);

  const analysisOptions = [
    {
      value: 'correlation',
      label: 'Correlation Analysis',
      description: 'Analyze relationship between two numeric variables',
    },
    {
      value: 'comparison',
      label: 'Group Comparison',
      description: 'Compare numeric values across groups',
    },
  ];

  // Extract column keys from metadata and clock_predictions
  const columnKeys = [
    ...new Set(
      gseData.metadata.flatMap((item) => [
        ...Object.keys(item).filter((key) => key !== 'clock_predictions'),
        ...(item.clock_predictions ? Object.keys(item.clock_predictions) : []),
      ])
    ),
  ].filter((key) => key !== 'geo_accession'); // Exclude geo_accession

  // Check if column is numeric
  const isNumericColumn = (key) => {
    const values = gseData.metadata
      .map((item) => {
        const value = item[key] ?? item.clock_predictions?.[key];
        return value;
      })
      .filter((v) => v != null);

    if (values.length === 0) return false;

    return values.every((v) => !isNaN(parseFloat(v)) && isFinite(parseFloat(v)));
  };

  // Check if column is categorical
  const isCategoricalColumn = (key) => {
    const values = gseData.metadata.map((item) => item[key] ?? item.clock_predictions?.[key]).filter((v) => v != null);

    const uniqueValues = new Set(values);
    return uniqueValues.size >= 2 && uniqueValues.size <= 20;
  };

  // Get appropriate columns for current analysis type
  const getAvailableColumns = (position) => {
    if (!analysisType) return columnKeys;

    if (analysisType === 'correlation') {
      // Both X and Y should be numeric for correlation
      return columnKeys.filter((key) => isNumericColumn(key));
    }

    if (analysisType === 'comparison') {
      // X should be numeric, Y should be categorical
      if (position === 'x') {
        return columnKeys.filter((key) => isNumericColumn(key));
      }
      if (position === 'y') {
        return columnKeys.filter((key) => isCategoricalColumn(key));
      }
    }

    return columnKeys;
  };

  // Reset selections when analysis type changes
  useEffect(() => {
    setXAxis('');
    setYAxis('');
    setSubgroupVariable('');
    setImageSrc(null);
    setTableData(null);
    setError(null);
  }, [analysisType]);

  const handleBackToPreviousStep = () => {
    navigate('/analysis/step2', { state: { gseData, selectedGSE } });
  };

  const fetchPlot = async () => {
    if (!analysisType || !xAxis || !yAxis) {
      setError('Please select analysis type, X-axis, and Y-axis variables');
      return;
    }

    setLoading(true);
    setError(null);

    try {
      const params = new URLSearchParams({
        x_label: xAxis,
        y_label: yAxis,
      });

      if (subgroupVariable) {
        params.append('subgroup', subgroupVariable);
      }

      const plotUrl = `/api/plot/${analysisType}/${selectedGSE}?${params.toString()}`;
      const response = await fetch(plotUrl);

      if (!response.ok) {
        const errorText = await response.text();
        let errorMessage = `Failed to fetch plot (${response.status})`;

        try {
          const errorJson = JSON.parse(errorText);
          errorMessage = errorJson.detail || errorMessage;
        } catch {
          errorMessage = errorText || errorMessage;
        }

        throw new Error(errorMessage);
      }

      const blob = await response.blob();

      // Revoke old URL to prevent memory leaks
      if (imageSrc) {
        URL.revokeObjectURL(imageSrc);
      }

      const url = URL.createObjectURL(blob);
      setImageSrc(url);
      setTableData(null);

      // Fetch stats for comparison
      if (analysisType === 'comparison') {
        try {
          const statsUrl = `/api/stats/comparison/${selectedGSE}?${params.toString()}`;
          const statsResponse = await fetch(statsUrl);

          if (statsResponse.ok) {
            const stats = await statsResponse.json();
            setTableData(stats);
          }
        } catch (statsError) {
          console.warn('Failed to fetch stats:', statsError);
          // Don't show error - stats are optional
        }
      }
    } catch (error) {
      console.error('Error fetching plot:', error);
      setError(error.message || 'Failed to generate plot');
      setImageSrc(null);
      setTableData(null);
    } finally {
      setLoading(false);
    }
  };

  const handleSaveImage = () => {
    if (imageSrc) {
      const link = document.createElement('a');
      link.href = imageSrc;
      link.download = `clockbase_${analysisType}_${selectedGSE}_${Date.now()}.png`;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
    }
  };

  // Cleanup URL on unmount
  useEffect(() => {
    return () => {
      if (imageSrc) {
        URL.revokeObjectURL(imageSrc);
      }
    };
  }, [imageSrc]);

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
            <div className='mb-8'>
              <h1 className='text-3xl font-semibold mb-2'>Step 3: Visualization & Statistical Analysis</h1>
              <p className='text-gray-400'>Generate correlation plots or group comparisons for {selectedGSE}</p>
            </div>

            {/* Error Message */}
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
              {/* Controls Panel */}
              <div className='w-full lg:w-80 bg-gray-900/50 backdrop-blur-sm rounded-lg border border-gray-800 p-6 space-y-5'>
                <h2 className='text-lg font-semibold mb-4'>Analysis Settings</h2>

                {/* Analysis Type */}
                <div>
                  <label className='block text-sm font-medium text-gray-300 mb-2'>Type of Analysis</label>
                  <div className='relative'>
                    <select
                      value={analysisType}
                      onChange={(e) => setAnalysisType(e.target.value)}
                      className='w-full bg-gray-800 border border-gray-700 rounded px-3 py-2.5 text-white focus:outline-none focus:border-blue-500 appearance-none cursor-pointer'
                    >
                      <option value=''>Select analysis type...</option>
                      {analysisOptions.map((opt) => (
                        <option key={opt.value} value={opt.value}>
                          {opt.label}
                        </option>
                      ))}
                    </select>
                    <ChevronLeft className='absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 rotate-[-90deg] pointer-events-none' />
                  </div>
                  {analysisType && (
                    <p className='mt-2 text-xs text-gray-400'>
                      {analysisOptions.find((o) => o.value === analysisType)?.description}
                    </p>
                  )}
                </div>

                {/* X-axis */}
                <div>
                  <label className='block text-sm font-medium text-gray-300 mb-2'>
                    X-axis {analysisType === 'comparison' && <span className='text-gray-500'>(numeric)</span>}
                  </label>
                  <div className='relative'>
                    <select
                      value={xAxis}
                      onChange={(e) => setXAxis(e.target.value)}
                      disabled={!analysisType}
                      className='w-full bg-gray-800 border border-gray-700 rounded px-3 py-2.5 text-white focus:outline-none focus:border-blue-500 appearance-none disabled:opacity-50 disabled:cursor-not-allowed cursor-pointer'
                    >
                      <option value=''>Select X-axis variable...</option>
                      {getAvailableColumns('x').map((key) => (
                        <option key={key} value={key}>
                          {key}
                        </option>
                      ))}
                    </select>
                    <ChevronLeft className='absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 rotate-[-90deg] pointer-events-none' />
                  </div>
                </div>

                {/* Y-axis */}
                <div>
                  <label className='block text-sm font-medium text-gray-300 mb-2'>
                    Y-axis {analysisType === 'comparison' && <span className='text-gray-500'>(categorical)</span>}
                  </label>
                  <div className='relative'>
                    <select
                      value={yAxis}
                      onChange={(e) => setYAxis(e.target.value)}
                      disabled={!analysisType}
                      className='w-full bg-gray-800 border border-gray-700 rounded px-3 py-2.5 text-white focus:outline-none focus:border-blue-500 appearance-none disabled:opacity-50 disabled:cursor-not-allowed cursor-pointer'
                    >
                      <option value=''>Select Y-axis variable...</option>
                      {getAvailableColumns('y').map((key) => (
                        <option key={key} value={key}>
                          {key}
                        </option>
                      ))}
                    </select>
                    <ChevronLeft className='absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 rotate-[-90deg] pointer-events-none' />
                  </div>
                </div>

                {/* Subgroup */}
                <div>
                  <label className='block text-sm font-medium text-gray-300 mb-2'>
                    Subgroup <span className='text-gray-500'>(optional)</span>
                  </label>
                  <div className='relative'>
                    <select
                      value={subgroupVariable}
                      onChange={(e) => setSubgroupVariable(e.target.value)}
                      disabled={!analysisType}
                      className='w-full bg-gray-800 border border-gray-700 rounded px-3 py-2.5 text-white focus:outline-none focus:border-blue-500 appearance-none disabled:opacity-50 disabled:cursor-not-allowed cursor-pointer'
                    >
                      <option value=''>No subgroup</option>
                      {columnKeys
                        .filter((k) => isCategoricalColumn(k))
                        .map((key) => (
                          <option key={key} value={key}>
                            {key}
                          </option>
                        ))}
                    </select>
                    <ChevronLeft className='absolute right-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400 rotate-[-90deg] pointer-events-none' />
                  </div>
                </div>

                {/* Submit Button */}
                <button
                  onClick={fetchPlot}
                  disabled={!analysisType || !xAxis || !yAxis || loading}
                  className={`w-full px-4 py-3 rounded-lg font-medium transition-all flex items-center justify-center gap-2 ${
                    !analysisType || !xAxis || !yAxis || loading
                      ? 'bg-gray-700 text-gray-400 cursor-not-allowed'
                      : 'bg-blue-800 hover:bg-blue-900 text-white shadow-lg shadow-blue-900/20 border border-blue-700/50'
                  }`}
                >
                  {loading ? (
                    <>
                      <Loader2 className='w-4 h-4 animate-spin' />
                      Generating...
                    </>
                  ) : (
                    'Generate Plot'
                  )}
                </button>
              </div>

              {/* Results Panel */}
              <div className='flex-1 min-w-0'>
                {loading && (
                  <div className='flex items-center justify-center h-96 bg-gray-900/30 rounded-lg border border-gray-800'>
                    <div className='text-center'>
                      <Loader2 className='w-12 h-12 animate-spin text-indigo-500 mx-auto mb-4' />
                      <p className='text-gray-400'>Generating visualization...</p>
                    </div>
                  </div>
                )}

                {!loading && imageSrc && (
                  <div className='space-y-6'>
                    <div className='bg-gray-900/30 rounded-lg border border-gray-800 p-4'>
                      <img src={imageSrc} alt='Analysis Plot' className='w-full h-auto rounded' />
                    </div>

                    {tableData && (
                      <div className='bg-gray-900/50 rounded-lg border border-gray-800 p-6'>
                        <h3 className='text-lg font-semibold mb-4'>Statistical Results</h3>
                        <div className='mb-4 p-3 bg-gray-800/50 rounded'>
                          <p className='text-sm'>
                            <span className='font-medium'>ANOVA p-value:</span>{' '}
                            <span
                              className={
                                parseFloat(tableData.anova_p_value) < 0.05 ? 'text-green-400 font-semibold' : ''
                              }
                            >
                              {tableData.anova_p_value}
                            </span>
                          </p>
                        </div>

                        <div className='overflow-x-auto'>
                          <table className='w-full border-collapse text-sm'>
                            <thead>
                              <tr className='bg-gray-800'>
                                {tableData.headers.map((header, i) => (
                                  <th key={i} className='px-4 py-3 text-left font-medium border-b border-gray-700'>
                                    {header}
                                  </th>
                                ))}
                              </tr>
                            </thead>
                            <tbody>
                              {tableData.data.map((row, rowIdx) => (
                                <tr
                                  key={rowIdx}
                                  className='border-b border-gray-800 hover:bg-gray-800/30'
                                  style={{
                                    backgroundColor:
                                      tableData.row_colors[rowIdx] === 'lightgreen'
                                        ? 'rgba(34, 197, 94, 0.1)'
                                        : 'transparent',
                                  }}
                                >
                                  {row.map((cell, cellIdx) => (
                                    <td key={cellIdx} className='px-4 py-3'>
                                      {cell}
                                    </td>
                                  ))}
                                </tr>
                              ))}
                            </tbody>
                          </table>
                        </div>
                      </div>
                    )}
                  </div>
                )}

                {!loading && !imageSrc && !error && (
                  <div className='flex items-center justify-center h-96 bg-gray-900/30 rounded-lg border border-gray-800 border-dashed'>
                    <p className='text-gray-500'>Select parameters and click "Generate Plot" to see results</p>
                  </div>
                )}
              </div>
            </div>

            {/* Navigation Buttons */}
            <div className='flex justify-between items-center mt-8'>
              <button
                onClick={handleBackToPreviousStep}
                className='flex items-center gap-2 px-4 py-2 text-gray-300 hover:text-white transition-colors'
              >
                <ArrowLeft className='w-4 h-4' />
                Back to Previous Step
              </button>

              <button
                onClick={handleSaveImage}
                disabled={!imageSrc}
                className={`flex items-center gap-2 px-6 py-2.5 rounded-lg font-medium transition-all ${
                  !imageSrc
                    ? 'bg-gray-700 text-gray-400 cursor-not-allowed'
                    : 'bg-blue-800 hover:bg-blue-900 text-white shadow-lg shadow-blue-900/20 border border-blue-700/50'
                }`}
              >
                <Download className='w-4 h-4' />
                Save Image
              </button>
            </div>
          </div>
        </div>

        <Footer />
      </div>
    </div>
  );
};

export default Step3Visualization;
