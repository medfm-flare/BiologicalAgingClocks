import ResponsiveNav from './ResponsiveNav.jsx';
import GeoDataBrowser from './GeoDataBrowser.jsx';
import ParticlesBackground from './ParticlesBackground.jsx';
import Footer from './Footer.jsx';
import background from '../assets/images/background.png';

const Step1GeoBrowser = () => {
  return (
    <div
      style={{
      background: `url(${background}), linear-gradient(150deg, #000000, rgb(13, 26, 50) 60%, rgb(40, 55, 75))`,
      backgroundSize: 'cover, auto',
      backgroundPosition: 'center, center',
      backgroundRepeat: 'no-repeat, no-repeat',
      backgroundBlendMode: 'soft-light',
      minHeight: '50vh',
      position: 'relative',
      overflow: 'hidden',
      fontFamily: 'Arial, sans-serif',
      display: 'flex',
      flexDirection: 'column',
    }}>
      <ParticlesBackground />
      <div style={{ position: 'relative', zIndex: 1, flex: 1, display: 'flex', flexDirection: 'column', }} className='min-h-screen'>
        <ResponsiveNav />
        <GeoDataBrowser />
        <Footer />
      </div>
      
    </div>
  )
}

export default Step1GeoBrowser;
