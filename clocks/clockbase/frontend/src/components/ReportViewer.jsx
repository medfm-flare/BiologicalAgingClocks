import React, { useState, useEffect, useRef } from 'react';

const ReportViewer = ({ gseId, onClose }) => {
  const [activeTab, setActiveTab] = useState('overview');
  const [outputData, setOutputData] = useState(null);
  const [miniPaper, setMiniPaper] = useState(null);
  const [overviewData, setOverviewData] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const requestIdRef = useRef(0);

  useEffect(() => {
    if (!gseId) {
      setOutputData(null);
      setMiniPaper(null);
      setOverviewData(null);
      return;
    }
    
    setOutputData(null);
    setMiniPaper(null);
    setOverviewData(null);
    
    const timeoutId = setTimeout(() => {
      loadReports(gseId);
    }, 150);
    
    return () => clearTimeout(timeoutId);
  }, [gseId]);

  const loadReports = async (id) => {
    const currentRequestId = ++requestIdRef.current;
    
    setLoading(true);
    setError(null);

    try {
      const overviewRes = await fetch(`/api/interventions/gse/${id}`);
      
      if (currentRequestId !== requestIdRef.current) return;
      
      if (overviewRes.ok) {
        const data = await overviewRes.json();
        setOverviewData(data);
        
        const caseId = data.case_id;
        
        if (data.has_output_data && caseId) {
          try {
            const outputRes = await fetch(`/api/interventions/report/${caseId}/output`);
            
            if (currentRequestId !== requestIdRef.current) return;
            
            if (outputRes.ok) {
              setOutputData(await outputRes.json());
            } else {
              setOutputData(null);
            }
          } catch (err) {
            if (currentRequestId !== requestIdRef.current) return;
            console.error('Error loading output data:', err);
            setOutputData(null);
          }
        }

        if (data.has_report && caseId) {
          try {
            const paperRes = await fetch(`/api/interventions/report/${caseId}/parsed?format=html`);
            
            if (currentRequestId !== requestIdRef.current) return;
            
            if (paperRes.ok) {
              const paperData = await paperRes.json();
              setMiniPaper(paperData);
            } else {
              setMiniPaper(null);
            }
          } catch (err) {
            if (currentRequestId !== requestIdRef.current) return;
            console.error('Error loading mini paper:', err);
            setMiniPaper(null);
          }
        }
      }
    } catch (error) {
      if (currentRequestId !== requestIdRef.current) return;
      
      console.error('Error loading reports:', error);
      setError('Failed to load reports');
    } finally {
      if (currentRequestId === requestIdRef.current) {
        setLoading(false);
      }
    }
  };

  if (!gseId) {
    return (
      <div style={styles.placeholder}>
        <div style={styles.placeholderIcon}>📊</div>
        <p style={styles.placeholderText}>
          Click on a point in the volcano plot or table row to view detailed reports
        </p>
        <p style={styles.placeholderSubtext}>
          Reports include experimental details, output data, and research mini papers
        </p>
      </div>
    );
  }

  return (
    <div style={styles.container}>
      <div style={styles.header}>
        <div>
          <h3 style={styles.title}>
            {overviewData?.intervention || gseId}
          </h3>
          <p style={styles.subtitle}>{gseId}</p>
        </div>
        {onClose && (
          <button onClick={onClose} style={styles.closeButton}>
            ✕
          </button>
        )}
      </div>

      <div style={styles.tabs}>
        <button
          onClick={() => setActiveTab('overview')}
          style={{
            ...styles.tab,
            ...(activeTab === 'overview' ? styles.tabActive : {})
          }}
        >
          Overview
        </button>
        <button
          onClick={() => setActiveTab('output')}
          style={{
            ...styles.tab,
            ...(activeTab === 'output' ? styles.tabActive : {}),
            ...(outputData ? {} : styles.tabDisabled)
          }}
          disabled={!outputData}
        >
          Output Data {!outputData && '(N/A)'}
        </button>
        <button
          onClick={() => setActiveTab('paper')}
          style={{
            ...styles.tab,
            ...(activeTab === 'paper' ? styles.tabActive : {}),
            ...(miniPaper ? {} : styles.tabDisabled)
          }}
          disabled={!miniPaper}
        >
          Mini Paper {!miniPaper && '(N/A)'}
        </button>
      </div>

      <div style={styles.content}>
        {loading && (
          <div style={styles.loading}>
            <div style={styles.loadingSpinner}></div>
            <div>Loading reports...</div>
          </div>
        )}

        {error && (
          <div style={styles.error}>{error}</div>
        )}

        {!loading && !error && (
          <>
            {activeTab === 'overview' && (
              <OverviewTab data={overviewData} />
            )}

            {activeTab === 'output' && outputData && (
              <OutputDataTab data={outputData} />
            )}

            {activeTab === 'paper' && miniPaper && (
              <MiniPaperTab paper={miniPaper} />
            )}
          </>
        )}
      </div>
    </div>
  );
};

// Overview Tab Component
const OverviewTab = ({ data }) => {
  if (!data) {
    return <div style={styles.loading}>No overview data available</div>;
  }

  return (
    <div style={styles.overviewContainer}>
      <Section title="Intervention Details">
        <InfoRow label="Intervention" value={data.intervention} />
        <InfoRow label="Condition" value={data.condition_name} />
        <InfoRow label="Category" value={data.condition_category} badge />
        <InfoRow label="Comparison" value={data.comparison_name} />
        <InfoRow label="Case ID" value={data.case_id} mono />
      </Section>

      <Section title="Statistical Results">
        <InfoRow label="Log2 Fold Change" value={data.log2FoldChange?.toFixed(3)} />
        <InfoRow label="P-value" value={data.pvalue?.toExponential(3)} />
        <InfoRow label="FDR" value={data.fdr?.toExponential(3)} />
        <InfoRow label="-log10(FDR)" value={data.neg_log10_fdr?.toFixed(2)} />
        <InfoRow label="Effect Direction" value={data.log2FoldChange > 0 ? 'Positive ↑' : 'Negative ↓'} />
      </Section>

      <Section title="Quality Metrics">
        <InfoRow label="Final Score" value={data.final_score?.toFixed(0)} />
        <InfoRow label="Trust Score" value={data.trust_score} />
        <InfoRow label="Statistical Test" value={data.statistical_test} />
      </Section>

      <Section title="Availability">
        <InfoRow 
          label="Output Data" 
          value={data.has_output_data ? '✓ Available' : '✗ Not available'} 
        />
        <InfoRow 
          label="Mini Paper" 
          value={data.has_report ? '✓ Available' : '✗ Not available'} 
        />
      </Section>
    </div>
  );
};

// Output Data Tab Component with Parsed Display
const OutputDataTab = ({ data }) => {
  if (!data) {
    return <div style={styles.loading}>No output data available</div>;
  }

  return (
    <div style={styles.outputContainer}>
      {/* Sample Information */}
      {data.sample && (
        <SampleSection sample={data.sample} />
      )}

      {/* Identified Relevance - Parsed */}
      {data.relevance && (
        <RelevanceSection relevance={data.relevance} />
      )}

      {/* Search Queries */}
      {data.queries && (
        <Section title="🔍 Search Queries">
          <div style={styles.queriesList}>
            {data.queries.map((query, idx) => (
              <div key={idx} style={styles.queryItem}>
                <span style={styles.queryNumber}>{idx + 1}.</span>
                <span style={styles.queryText}>{query}</span>
              </div>
            ))}
          </div>
        </Section>
      )}

      {!data.relevance && !data.queries && !data.sample && (
        <div style={styles.empty}>No output data files found</div>
      )}
    </div>
  );
};

// Sample Section Component
const SampleSection = ({ sample }) => {
  return (
    <Section title="📋 Study Information">
      <div style={styles.sampleGrid}>
        <InfoRow label="GSE ID" value={sample.gse_id} mono />
        <InfoRow label="Title" value={sample.title} fullWidth />
        <InfoRow label="Category" value={sample.condition_category} badge />
        <InfoRow label="Comparison" value={sample.comparison_name} />
        <InfoRow label="Condition" value={sample.condition_name} />
        <InfoRow label="Effect Size" value={sample.effect_size?.toFixed(3)} />
        <InfoRow label="P-value" value={sample.pvalue?.toExponential(3)} />
        <InfoRow label="Direction" value={sample.direction > 0 ? '↑ Positive' : '↓ Negative'} />
        <InfoRow label="Outlier Status" value={sample.outlier_status} />
        {sample.overall_design && (
          <InfoRow label="Design" value={sample.overall_design} fullWidth />
        )}
      </div>

      {sample.summary && (
        <div style={styles.summaryBox}>
          <div style={styles.summaryLabel}>Study Summary:</div>
          <div style={styles.summaryText}>{sample.summary}</div>
        </div>
      )}

      {sample.citations && sample.citations.length > 0 && (
        <div style={styles.citationsBox}>
          <div style={styles.summaryLabel}>Citations:</div>
          {sample.citations.map((citation, idx) => (
            <div key={idx} style={styles.citationItem}>
              <a 
                href={citation.pubmed_url} 
                target="_blank" 
                rel="noopener noreferrer"
                style={styles.citationLink}
              >
                {citation.full_citation}
              </a>
              {citation.abstract && (
                <div style={styles.citationAbstract}>{citation.abstract}</div>
              )}
            </div>
          ))}
        </div>
      )}
    </Section>
  );
};

// Relevance Section Component
const RelevanceSection = ({ relevance }) => {
  const criteriaOrder = [
    'q1_experimental_model',
    'q2_1_aging_pathways',
    'q2_2_age_diseases',
    'q3_1_experimental_rigor',
    'q4_1_translational_potential',
    'q5_1_literature_saturation',
    'q5_2_mechanistic_novelty',
    'q0_plausibility'
  ];

  const criteriaLabels = {
    'q1_experimental_model': '🔬 Experimental Model',
    'q2_1_aging_pathways': '🧬 Aging Pathways',
    'q2_2_age_diseases': '🏥 Age-Related Diseases',
    'q3_1_experimental_rigor': '📊 Experimental Rigor',
    'q4_1_translational_potential': '💊 Translational Potential',
    'q5_1_literature_saturation': '📚 Literature Saturation',
    'q5_2_mechanistic_novelty': '💡 Mechanistic Novelty',
    'q0_plausibility': '✓ Plausibility Check'
  };

  const finalScore = relevance.final_score;
  const intervention = relevance.q6_intervention;

  return (
    <Section title="⭐ Quality Assessment & Scoring">
      {/* Final Score Banner */}
      <div style={styles.scoreBanner}>
        <div style={styles.scoreMain}>
          <div style={styles.scoreLabel}>Final Score</div>
          <div style={styles.scoreValue}>{finalScore}</div>
        </div>
        {intervention && (
          <div style={styles.scoreIntervention}>
            <div style={styles.scoreInterventionLabel}>Intervention:</div>
            <div style={styles.scoreInterventionValue}>{intervention}</div>
          </div>
        )}
      </div>

      {/* Criteria Breakdown */}
      <div style={styles.criteriaContainer}>
        {criteriaOrder.map((key) => {
          const criterion = relevance[key];
          if (!criterion) return null;

          const label = criteriaLabels[key] || key;
          const points = criterion.points ?? criterion.penalty_or_bonus_applied ?? 0;
          const rationale = criterion.rationale || 'No rationale provided';

          return (
            <div key={key} style={styles.criterionCard}>
              <div style={styles.criterionHeader}>
                <span style={styles.criterionLabel}>{label}</span>
                <span style={{
                  ...styles.criterionPoints,
                  color: points > 0 ? '#27ae60' : points < 0 ? '#e74c3c' : '#95a5a6'
                }}>
                  {points > 0 ? '+' : ''}{points} pts
                </span>
              </div>
              <div style={styles.criterionRationale}>{rationale}</div>
            </div>
          );
        })}
      </div>
    </Section>
  );
};

// Mini Paper Tab Component
const MiniPaperTab = ({ paper }) => {
  return (
    <div style={styles.paperContainer}>
      <iframe
        srcDoc={paper.content}
        style={styles.iframe}
        title="Mini Paper"
        sandbox="allow-same-origin"
      />
    </div>
  );
};

// Helper Components
const Section = ({ title, children }) => (
  <div style={styles.section}>
    <h4 style={styles.sectionTitle}>{title}</h4>
    <div style={styles.sectionContent}>{children}</div>
  </div>
);

const InfoRow = ({ label, value, badge, mono, fullWidth }) => (
  <div style={{...styles.infoRow, ...(fullWidth ? styles.infoRowFull : {})}}>
    <span style={styles.infoLabel}>{label}:</span>
    {badge ? (
      <span style={styles.badge}>{value}</span>
    ) : mono ? (
      <span style={{...styles.infoValue, fontFamily: 'Monaco, Consolas, monospace', fontSize: '12px'}}>{value}</span>
    ) : (
      <span style={styles.infoValue}>{value}</span>
    )}
  </div>
);

// Styles
const styles = {
  container: {
    display: 'flex',
    flexDirection: 'column',
    height: '100%',
    color: 'white'
  },
  placeholder: {
    display: 'flex',
    flexDirection: 'column',
    justifyContent: 'center',
    alignItems: 'center',
    height: '100%',
    textAlign: 'center',
    padding: '40px'
  },
  placeholderIcon: {
    fontSize: '64px',
    marginBottom: '20px',
    opacity: 0.5
  },
  placeholderText: {
    fontSize: '18px',
    marginBottom: '10px',
    color: 'rgba(255, 255, 255, 0.9)'
  },
  placeholderSubtext: {
    fontSize: '14px',
    color: 'rgba(255, 255, 255, 0.6)'
  },
  header: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'flex-start',
    padding: '20px',
    borderBottom: '1px solid rgba(255, 255, 255, 0.1)'
  },
  title: {
    margin: 0,
    fontSize: '20px',
    fontWeight: 'bold'
  },
  subtitle: {
    margin: '5px 0 0 0',
    fontSize: '14px',
    color: 'rgba(255, 255, 255, 0.6)',
    fontFamily: 'Monaco, Consolas, monospace'
  },
  closeButton: {
    background: 'none',
    border: 'none',
    color: 'white',
    fontSize: '24px',
    cursor: 'pointer',
    padding: '0',
    width: '30px',
    height: '30px',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: '4px',
    transition: 'background 0.2s'
  },
  tabs: {
    display: 'flex',
    borderBottom: '2px solid rgba(255, 255, 255, 0.1)',
    padding: '0 20px'
  },
  tab: {
    background: 'none',
    border: 'none',
    color: 'rgba(255, 255, 255, 0.6)',
    padding: '12px 20px',
    cursor: 'pointer',
    fontSize: '14px',
    borderBottom: '2px solid transparent',
    marginBottom: '-2px',
    transition: 'all 0.2s'
  },
  tabActive: {
    color: 'white',
    borderBottomColor: '#B5BBA9'
  },
  tabDisabled: {
    opacity: 0.4,
    cursor: 'not-allowed'
  },
  content: {
    flex: 1,
    overflow: 'auto',
    padding: '20px'
  },
  loading: {
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    justifyContent: 'center',
    padding: '40px',
    color: 'rgba(255, 255, 255, 0.6)',
    gap: '16px'
  },
  loadingSpinner: {
    width: '40px',
    height: '40px',
    border: '4px solid rgba(255, 255, 255, 0.08)',
    borderTop: '4px solid #B5BBA9',
    borderRadius: '50%',
    animation: 'spin 1s linear infinite'
  },
  error: {
    textAlign: 'center',
    padding: '40px',
    color: '#e74c3c'
  },
  overviewContainer: {
    display: 'flex',
    flexDirection: 'column',
    gap: '20px'
  },
  outputContainer: {
    display: 'flex',
    flexDirection: 'column',
    gap: '20px'
  },
  section: {
    background: 'rgba(255, 255, 255, 0.03)',
    borderRadius: '8px',
    padding: '15px',
    border: '1px solid rgba(255, 255, 255, 0.1)'
  },
  sectionTitle: {
    margin: '0 0 15px 0',
    fontSize: '16px',
    fontWeight: 'bold',
    color: '#B5BBA9'
  },
  sectionContent: {
    display: 'flex',
    flexDirection: 'column',
    gap: '8px'
  },
  infoRow: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: '8px 0',
    gap: '12px'
  },
  infoRowFull: {
    flexDirection: 'column',
    alignItems: 'flex-start',
    gap: '6px'
  },
  infoLabel: {
    color: 'rgba(255, 255, 255, 0.7)',
    fontSize: '14px',
    flexShrink: 0
  },
  infoValue: {
    color: 'white',
    fontSize: '14px',
    fontWeight: '500',
    textAlign: 'right',
    wordBreak: 'break-word'
  },
  badge: {
    background: 'rgba(181, 187, 169, 0.2)',
    color: '#B5BBA9',
    padding: '4px 12px',
    borderRadius: '12px',
    fontSize: '13px',
    fontWeight: '500'
  },
  sampleGrid: {
    display: 'flex',
    flexDirection: 'column',
    gap: '8px'
  },
  summaryBox: {
    marginTop: '12px',
    padding: '12px',
    background: 'rgba(0, 0, 0, 0.2)',
    borderRadius: '6px',
    borderLeft: '3px solid #B5BBA9'
  },
  summaryLabel: {
    fontSize: '13px',
    fontWeight: '600',
    color: '#B5BBA9',
    marginBottom: '8px'
  },
  summaryText: {
    fontSize: '13px',
    lineHeight: '1.6',
    color: 'rgba(255, 255, 255, 0.85)'
  },
  citationsBox: {
    marginTop: '12px',
    padding: '12px',
    background: 'rgba(0, 0, 0, 0.2)',
    borderRadius: '6px'
  },
  citationItem: {
    marginTop: '8px',
    paddingTop: '8px',
    borderTop: '1px solid rgba(255, 255, 255, 0.1)'
  },
  citationLink: {
    color: '#3498db',
    textDecoration: 'none',
    fontSize: '13px',
    fontWeight: '500'
  },
  citationAbstract: {
    marginTop: '6px',
    fontSize: '12px',
    lineHeight: '1.5',
    color: 'rgba(255, 255, 255, 0.7)',
    fontStyle: 'italic'
  },
  scoreBanner: {
    background: 'linear-gradient(135deg, rgba(181, 187, 169, 0.15), rgba(181, 187, 169, 0.05))',
    padding: '20px',
    borderRadius: '8px',
    border: '2px solid rgba(181, 187, 169, 0.3)',
    marginBottom: '16px',
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    flexWrap: 'wrap',
    gap: '16px'
  },
  scoreMain: {
    display: 'flex',
    alignItems: 'center',
    gap: '16px'
  },
  scoreLabel: {
    fontSize: '14px',
    color: 'rgba(255, 255, 255, 0.7)',
    fontWeight: '500'
  },
  scoreValue: {
    fontSize: '36px',
    fontWeight: 'bold',
    color: '#B5BBA9'
  },
  scoreIntervention: {
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'flex-end',
    gap: '4px'
  },
  scoreInterventionLabel: {
    fontSize: '12px',
    color: 'rgba(255, 255, 255, 0.6)'
  },
  scoreInterventionValue: {
    fontSize: '16px',
    fontWeight: '600',
    color: 'white'
  },
  criteriaContainer: {
    display: 'flex',
    flexDirection: 'column',
    gap: '12px'
  },
  criterionCard: {
    background: 'rgba(0, 0, 0, 0.2)',
    padding: '12px',
    borderRadius: '6px',
    border: '1px solid rgba(255, 255, 255, 0.08)'
  },
  criterionHeader: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: '8px'
  },
  criterionLabel: {
    fontSize: '14px',
    fontWeight: '600',
    color: 'white'
  },
  criterionPoints: {
    fontSize: '14px',
    fontWeight: 'bold',
    fontFamily: 'Monaco, Consolas, monospace'
  },
  criterionRationale: {
    fontSize: '13px',
    lineHeight: '1.5',
    color: 'rgba(255, 255, 255, 0.8)'
  },
  queriesList: {
    display: 'flex',
    flexDirection: 'column',
    gap: '10px'
  },
  queryItem: {
    display: 'flex',
    gap: '10px',
    padding: '10px',
    background: 'rgba(0, 0, 0, 0.2)',
    borderRadius: '6px',
    border: '1px solid rgba(255, 255, 255, 0.08)'
  },
  queryNumber: {
    color: '#B5BBA9',
    fontWeight: 'bold',
    fontSize: '13px',
    flexShrink: 0
  },
  queryText: {
    fontSize: '13px',
    lineHeight: '1.5',
    color: 'rgba(255, 255, 255, 0.85)'
  },
  empty: {
    textAlign: 'center',
    padding: '40px',
    color: 'rgba(255, 255, 255, 0.5)',
    fontSize: '14px'
  },
  paperContainer: {
    height: 'calc(100vh - 300px)',
    minHeight: '400px'
  },
  iframe: {
    width: '100%',
    height: '100%',
    border: 'none',
    borderRadius: '8px',
    background: 'white'
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

export default ReportViewer;