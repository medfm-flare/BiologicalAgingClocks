// src/main.jsx
import ReactDOM from 'react-dom/client';
import App from './components/App';
import ClockAtlasView from './components/ClockAtlasView'
import Step1GeoBrowser from './components/Step1GeoBrowser';
import Step2BiologicalAge from './components/Step2BiologicalAge';
import Step3Visualization from './components/Step3Visualization';
import ClockInfo from './components/ClockInfo';
import About from './components/About';
import InterventionsView from './components/InterventionsView';
import { BrowserRouter, Routes, Route } from "react-router";
import './styles.css';

const NotFound = () => <div>404 - Page Not Found</div>;

ReactDOM.createRoot(document.getElementById('root')).render(
  <BrowserRouter>
    <Routes>
      <Route index element={<App />} />
      <Route path="clock-atlas" element={<ClockAtlasView />} />
      <Route path="analysis/step1" element={<Step1GeoBrowser />} />
      <Route path="analysis/step2" element={<Step2BiologicalAge />} />
      <Route path="analysis/step3" element={<Step3Visualization />} />
      <Route path="clock-info" element={<ClockInfo/ >} />
      <Route path="about" element={<About/ >} />
      <Route path="interventions" element={<InterventionsView />} />
      <Route path="*" element={<NotFound />} />
    </Routes>
  </BrowserRouter>
);