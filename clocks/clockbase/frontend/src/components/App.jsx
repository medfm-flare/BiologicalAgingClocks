import { useNavigate } from 'react-router-dom';
import { useState, useEffect } from 'react';
import ResponsiveNav from './ResponsiveNav.jsx';
import Footer from './Footer.jsx';
import mobileBackground from '../assets/images/mobile_background.png';

const App = () => {
  const navigate = useNavigate();

  const calculateTranslateX = (screenWidth) => {
    if (screenWidth >= 1560) {
      return 26 + ((screenWidth - 1560) / (1602 - 1560)) * (15 - 0);
    } else if (screenWidth >= 1400) {
      return -30 + ((screenWidth - 1400) / (1560 - 1400)) * (26 - -30);
    } else if (screenWidth >= 1200) {
      return -105 + ((screenWidth - 1200) / (1400 - 1200)) * (-30 - -105);
    } else if (screenWidth >= 986) {
      return -203 + ((screenWidth - 986) / (1200 - 986)) * (-105 - -203);
    } else {
      return -203 + ((screenWidth - 986) / (1200 - 986)) * (-105 - -203);
    }
  };

  const calculateWidth = (screenWidth, translateX) => {
    const requiredWidth = (screenWidth + 1.4 * Math.abs(translateX)) / 1.2;
    return Math.max(screenWidth, requiredWidth);
  };

  const calculateScale = (screenHeight) => {
    const baseHeight = 1080;
    const minScale = 1;
    const maxScale = 1.5;

    let scale = (screenHeight / baseHeight) * 1.5;
    return Math.min(Math.max(scale, minScale), maxScale);
  };

  const [scale, setScale] = useState(() => calculateScale(window.innerHeight));
  const [translateX, setTranslateX] = useState(() => calculateTranslateX(window.innerWidth));
  const [translateY, setTranslateY] = useState(30);
  const [viewerWidth, setViewerWidth] = useState(() =>
    calculateWidth(window.innerWidth, calculateTranslateX(window.innerWidth))
  );
  const [isMobile, setIsMobile] = useState(window.innerWidth <= 768);

  useEffect(() => {
    const handleResize = () => {
      const newScale = calculateScale(window.innerHeight);
      setScale(newScale);

      const baseTranslateX = calculateTranslateX(window.innerWidth);

      const ANCHOR_X = 450;
      const adjustedTranslateX = (baseTranslateX + ANCHOR_X) * (1.4 / newScale) - ANCHOR_X;
      const adjustedTranslateY = window.innerHeight < 860 ? 35 : 30;
      setTranslateX(adjustedTranslateX);
      setTranslateY(adjustedTranslateY);
      setViewerWidth(calculateWidth(window.innerWidth, adjustedTranslateX));
      setIsMobile(window.innerWidth <= 768);
    };

    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  useEffect(() => {
    const baseTranslateX = calculateTranslateX(window.innerWidth);

    const ANCHOR_X = 450;
    const adjustedTranslateX = (baseTranslateX + ANCHOR_X) * (1.4 / scale) - ANCHOR_X;

    setTranslateX(adjustedTranslateX);
    setViewerWidth(calculateWidth(window.innerWidth, adjustedTranslateX));
  }, [scale]);

  const ActionButton = ({ onClick, label }) => (
    <button
      onClick={onClick}
      className='backdrop-blur-[2px] border border-white/70 text-white rounded-lg cursor-pointer text-base font-medium transition-all duration-300 w-[180px] h-[50px] font-citrine hover:-translate-y-0.5 bg-white/5 hover:bg-white/10 max-md:text-sm max-md:w-auto max-md:px-4'
    >
      {label}
    </button>
  );

  return (
    <div className='w-screen h-screen relative overflow-hidden text-white bg-black'>
      {/* Background */}
      {isMobile ? (
        <div
          className='absolute top-[100px] left-0 w-full h-[calc(100%-160px)] z-0 bg-contain bg-top bg-no-repeat'
          style={{
            backgroundImage: `url(${mobileBackground})`,
          }}
        />
      ) : (
        <spline-viewer
          url='interactiveclock.spline'
          style={{
            position: 'absolute',
            top: 0,
            left: 0,
            width: `${viewerWidth}px`,
            height: 'calc(100% - 60px)',
            zIndex: 0,
            transform: `scale(${scale}) translateY(${translateY}px) translateX(${translateX}px)`,
          }}
        ></spline-viewer>
      )}

      {/* Gradient Overlay for better text visibility */}
      <div
        className={`absolute top-0 left-0 w-full h-full z-[1] pointer-events-none ${
          isMobile
            ? 'bg-gradient-to-t from-black via-black/90 to-transparent via-35%'
            : 'bg-gradient-to-r from-black via-black/90 to-transparent via-35%'
        }`}
      />

      <div className='flex flex-col h-full relative z-[2] pointer-events-none'>
        <div className='pointer-events-auto'>
          <ResponsiveNav />
        </div>

        <main
          className={`flex-1 flex flex-col justify-center max-w-[700px] w-full pointer-events-none ${
            isMobile
              ? 'justify-end px-6 text-center items-center mb-10 max-w-full ml-0'
              : 'px-[5vw] ml-[5vw] text-left items-start'
          }`}
        >
          {/* Main Heading */}
          <h1
            className={`text-white font-normal leading-[1.2] mb-10 max-w-[800px] font-citrine ${
              isMobile ? 'text-[28px]' : 'text-[32px]'
            }`}
          >
            Discovering Hidden Aging Interventions with AI Agent
          </h1>

          {/* Action Buttons */}
          <div
            className={`flex flex-row gap-5 mb-[28px] flex-wrap items-center w-auto pointer-events-auto ${
              isMobile ? 'gap-3 justify-center w-full' : 'justify-start'
            }`}
          >
            <ActionButton onClick={() => navigate('/interventions')} label='AI Agent Analysis' />
            <ActionButton onClick={() => navigate('/analysis/step1')} label='Manual Analysis' />
            <ActionButton onClick={() => navigate('/clock-atlas')} label='Sample Atlas' />
          </div>
        </main>
        <div
          className={`absolute bottom-[75px] text-white text-xs font-citrine z-[2] pointer-events-auto whitespace-nowrap ${
            isMobile ? 'left-1/2 -translate-x-1/2 px-0 max-w-full ml-0' : 'left-0 px-[5vw] max-w-[700px] ml-[5vw]'
          }`}
        >
          Copyright © 2025 Kejun Ying @ Gladyshev lab
        </div>

        {/* Footer */}
        <Footer />
      </div>
    </div>
  );
};

export default App;
