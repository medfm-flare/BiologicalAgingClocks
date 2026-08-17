import React from 'react';
import { useLocation } from 'react-router-dom';
import footerImage from '../assets/images/footer.png';

const Footer = () => {
  const location = useLocation();
  const isLandingPage = location.pathname === '/';

  if (!isLandingPage) {
    return null;
  }

  return (
    <footer
      style={{
        width: '100%',
        height: '60px',
        display: 'flex',
        justifyContent: 'flex-start',
        alignItems: 'center',
        overflowX: 'auto',
        overflowY: 'hidden',
        position: 'relative',
        background: 'black',
        zIndex: 1000,
        scrollbarWidth: 'none',
        msOverflowStyle: 'none',
        pointerEvents: 'auto',
      }}
    >
      <style>
        {`
                footer::-webkit-scrollbar {
                    display: none;
                }
            `}
      </style>
      <img
        src={footerImage}
        alt='Footer Logos'
        style={{
          height: '100%',
          width: 'auto',
          minWidth: '100%',
          maxWidth: 'none',
          objectFit: 'cover',
          flexShrink: 0,
        }}
      />
    </footer>
  );
};

export default Footer;
