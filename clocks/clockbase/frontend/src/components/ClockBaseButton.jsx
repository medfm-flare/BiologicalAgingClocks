import { Link, useNavigate } from 'react-router-dom';
import { ROUTES } from '../config/routes';

const ClockBaseButton = ({ text, onClick, showArrow = false, isOpen = false }) => {
  const navigate = useNavigate();
  const route = ROUTES[text];

  const handleClick = (e) => {
    if (onClick) {
      onClick(e); // Custom onClick (e.g., for Explore dropdown)
    } else if (route) {
      navigate(route); // Programmatic navigation as fallback
    }
  };

  const ButtonContent = (
    <button
      className={`clock-atlas-button font-citrine ${isOpen ? 'open' : ''}`}
      style={{
        borderRadius: '7px',
        color: 'white',
        display: 'inline-block',
        cursor: 'pointer',
        fontSize: '14px',
        transition: 'all 0.3s ease',
        outline: 'none',
      }}
      onClick={handleClick}
    >
      {text}
      {showArrow && (
        <span
          style={{
            padding: '5px 10px',
            fontSize: '10px',
          }}
        >
          ▼
        </span>
      )}
    </button>
  );

  return (
    <div
      style={{
        display: 'inline-flex',
        border: 'double 2px transparent',
        borderRadius: '10px',
        backgroundImage:
          'linear-gradient(#0505137F, #0505137F), radial-gradient(circle at top left, #1E5AA07F, #0A28507F)',
        backgroundOrigin: 'border-box',
        backgroundClip: 'content-box, border-box',
      }}
    >
      {route && !onClick ? <Link to={route}>{ButtonContent}</Link> : ButtonContent}
    </div>
  );
};

export default ClockBaseButton;
