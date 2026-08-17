import React, { useState } from 'react';
import ClockBaseButton from './ClockBaseButton';
import logo from '../assets/images/logo.png';
import { useNavigate } from 'react-router-dom';

const ResponsiveNav = () => {
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const navigate = useNavigate();

  const toggleMenu = () => {
    setIsMenuOpen(!isMenuOpen);
  };

  return (
    <header
      style={{
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        padding: '20px 40px',
        position: 'relative',
        zIndex: 10,
      }}
    >
      {/* Logo */}
      <div
        style={{
          width: '100px',
          height: '100px',
        }}
      >
        <img
          className='nav-logo'
          onClick={() => navigate('/')}
          src={logo}
          alt='Logo'
          style={{
            width: '100%',
            height: '100%',
            objectFit: 'contain',
            filter: 'saturate(200%) brightness(510%) contrast(120%)',
          }}
        />
      </div>

      {/* Navigation Menu */}
      <nav
        style={{
          display: 'flex',
          alignItems: 'center',
          position: 'relative',
        }}
      >
        {/* Hamburger Icon for Mobile */}
        <button
          style={{
            display: 'none', // Hidden on desktop
            background: 'none',
            border: 'none',
            color: 'white',
            fontSize: '30px',
            cursor: 'pointer',
            padding: '10px',
            zIndex: 1000,
          }}
          className='hamburger'
          onClick={toggleMenu}
          aria-label='Toggle menu'
        >
          {isMenuOpen ? '✕' : '☰'}
        </button>

        {/* Menu Items */}
        <div
          style={{
            display: 'flex',
            gap: '20px',
            alignItems: 'center',
          }}
          className={`menu ${isMenuOpen ? 'open' : ''}`}
        >
          <ClockBaseButton text='AI Agent Analysis' onClick={() => navigate('/interventions')} />
          <ClockBaseButton text='Manual Analysis' onClick={() => navigate('/analysis/step1')} />
          <ClockBaseButton text='Sample Atlas' onClick={() => navigate('/clock-atlas')} />
          <ClockBaseButton text='Clock Info' onClick={() => navigate('/clock-info')} />
          <ClockBaseButton text='About' onClick={() => navigate('/about')} />
        </div>
      </nav>
    </header>
  );
};

export default ResponsiveNav;
