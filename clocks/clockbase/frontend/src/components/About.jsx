import ParticlesBackground from './ParticlesBackground.jsx';
import ResponsiveNav from './ResponsiveNav.jsx';
import figure1_dark from '../assets/images/figure1_dark.png';

const About = () => {
  return (
    <div className='min-h-screen bg-gradient-to-br from-black via-blue-950 to-slate-900 text-white p-6'>
      <ParticlesBackground />
      <ResponsiveNav />
      <div
        className='bg-gray-900/80 rounded-lg border border-gray-800 px-6 md:px-30 py-10 mx-4 md:mx-40'
        style={{
          position: 'relative',
          zIndex: 1,
          flex: 1,
          display: 'flex',
          flexDirection: 'column',
        }}
      >
        {/* Title */}
        <h1 className='font-bold text-5xl my-3'>About ClockBase Agent</h1>

        {/* Unlocking Hidden Discoveries */}
        <h2 className='font-semibold text-2xl mt-6 mb-3'>Unlocking Hidden Discoveries in Decades of Research</h2>
        <p className='my-3'>
          ClockBase Agent addresses a fundamental inefficiency in biomedical research: decades of publicly available
          molecular data, representing billions of dollars in research investment and millions of samples, have never
          been systematically analyzed through the lens of biological aging. We demonstrate how autonomous AI agents can
          unlock this untapped resource by reanalyzing all existing data to discover therapeutic interventions hidden in
          plain sight.
        </p>

        {/* Figure */}
        <div className='my-6'>
          <img
            src={figure1_dark}
            alt='ClockBase Agent platform architecture showing data integration, AI agent workflow, and systematic discovery process'
            className='w-full rounded-lg shadow-lg'
          />
          <p className='mt-2 text-sm text-gray-300 italic'>
            ClockBase Agent platform architecture showing data integration, AI agent workflow, and systematic discovery
            process
          </p>
        </div>

        {/* What We Do */}
        <h2 className='font-semibold text-2xl mt-6 mb-3'>What We Do</h2>
        <p className='my-3'>
          ClockBase integrates approximately 2 million human and mouse molecular profiles with over 40 aging clock
          predictions. Our specialized AI agents autonomously generate hypotheses, execute statistical analyses, conduct
          literature reviews, and produce scientific reports across thousands of datasets without human intervention.
        </p>
        <p className='my-3'>
          Analysis of 43,602 intervention-control comparisons revealed thousands of age-modifying effects missed by
          original investigators, including over 500 interventions that significantly reduce biological age. The agent
          framework achieved 99% analytical accuracy across rigorous validation by independent experts, demonstrating
          that AI systems can now handle sophisticated scientific reasoning that previously required domain expertise.
        </p>

        {/* Validated Discovery */}
        <h2 className='font-semibold text-2xl mt-6 mb-3'>Validated Discovery</h2>
        <p className='my-3'>
          We experimentally validated ouabain, a top-scoring AI-identified candidate not previously studied for
          anti-aging effects. Treatment significantly reduced frailty progression, improved cardiac function, and
          decreased neuroinflammation in aged mice, confirming that our AI-driven discovery pipeline identifies
          compounds with genuine therapeutic potential.
        </p>

        {/* Why This Matters */}
        <h2 className='font-semibold text-2xl mt-6 mb-3'>Why This Matters</h2>
        <p className='my-3'>
          This work establishes a new paradigm where AI agents systematically reanalyze all prior research to extract
          insights that human investigators missed. This approach is immediately applicable to any field with
          large-scale molecular databases, including cancer biology, immunology, neuroscience, and metabolic disease
          research.
        </p>
        <p className='my-3'>
          The platform democratizes access to sophisticated aging biomarker analyses, enabling any investigator
          worldwide to test hypotheses against millions of samples instantly. For clinical translation, our systematic
          identification of compounds that improve multiple health parameters in aged animals provides a foundation for
          developing interventions to extend human healthspan.
        </p>

        {/* A Public Resource */}
        <h2 className='font-semibold text-2xl mt-6 mb-3'>A Public Resource</h2>
        <p className='my-3'>
          All biological age predictions and analysis results are freely accessible at{' '}
          <a
            href='https://www.clockbase.org'
            className='underline text-blue-300 hover:text-blue-500 visited:text-purple-600'
          >
            www.clockbase.org
          </a>
          . The platform provides interactive tools for statistical analysis across all datasets, ensuring this resource
          catalyzes discoveries by the global scientific community.
        </p>

        {/* Contact */}
        <h2 className='font-semibold text-2xl mt-6 mb-3'>Contact</h2>
        <p className='my-3'>
          Follow us on 𝕏:{' '}
          <a
            className='underline text-blue-300 hover:text-blue-500 visited:text-purple-600'
            href='https://twitter.com/KejunYing'
          >
            @KejunYing
          </a>{' '}
          and{' '}
          <a
            className='underline text-blue-300 hover:text-blue-500 visited:text-purple-600'
            href='https://twitter.com/gladyshev_lab'
          >
            @gladyshev_lab
          </a>
        </p>

        {/* Cite Us */}
        <h2 className='font-semibold text-2xl mt-6 mb-3'>Cite Us</h2>
        <p className='my-3'>
          <span className='font-semibold'>AI Agent platform:</span> K. Ying, A. Tyshkovskiy, A. Moldakozhayev, H. Wang,
          et al. Autonomous AI Agents Discover Aging Interventions from Millions of Molecular Profiles. <em>bioRxiv</em>{' '}
          (2025). doi:10.1101/2023.02.28.530532
        </p>

        {/* Acknowledgements */}
        <h2 className='font-semibold text-2xl mt-6 mb-3'>Acknowledgements</h2>
        <p className='my-3'>
          ClockBase Agent was developed with major contributions from Kejun Ying, Alexander Tyshkovskiy, Hanchen Wang,
          Alibek Moldakozhayev, and many collaborators. We thank the Biomarkers of Aging Consortium, the Biolearn team,
          and the NIH/NIA for support (F99AG088431 and K00AG088431 to K.Y.). We thank Avinasi Labs for providing API
          credit support for our AI agent processing.
        </p>

        {/* Disclaimer */}
        <h2 className='font-semibold text-2xl mt-6 mb-3'>Disclaimer</h2>
        <p className='my-3'>
          This platform is intended for research and academic purposes only. AI-generated analyses and intervention
          predictions should not be used for clinical decisions without rigorous experimental validation and regulatory
          approval. Some aging clocks may be subject to patents or licenses. Consult original publications for
          appropriate usage guidance.
        </p>
      </div>
    </div>
  );
};

export default About;
