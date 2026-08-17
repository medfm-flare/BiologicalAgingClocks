import React, { useRef, useEffect, useState } from 'react';
import * as THREE from 'three';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls';
import { tableFromIPC } from 'apache-arrow';
import { ChevronDown } from 'lucide-react';
import ResponsiveNav from './ResponsiveNav';
import Footer from './Footer';
import ColorBar from './ColorBar';
import ParticlesBackground from './ParticlesBackground';

const COLOR_PALETTE = ['#1F3481', '#6596A1', '#E9C64F', '#D76938', '#C93929'];

export default function ClockAtlasView() {
  const mountRef = useRef(null);
  const rendererRef = useRef(null);
  const cameraRef = useRef(null);
  const sceneRef = useRef(null);
  const controlsRef = useRef(null);
  const pointsRef = useRef(null);
  const raycaster = useRef(new THREE.Raycaster());
  const mouseNorm = useRef(new THREE.Vector2());

  const [analysis, setAnalysis] = useState('PhenoAge');
  const [method, setMethod] = useState('tsne');
  const [hovered, setHovered] = useState(null);
  const [cursorPos, setCursorPos] = useState({ x: 0, y: 0 });
  const [isAnalysisOpen, setIsAnalysisOpen] = useState(false);
  const [isMethodOpen, setIsMethodOpen] = useState(false);
  const [min, setMin] = useState(0);
  const [max, setMax] = useState(0);
  const [loading, setLoading] = useState(false);

  const analyses = [
    'PhenoAge',
    'HorvathAge',
    'HannumAge',
    'DunedinPACE',
    'DunedinPoAm',
    'PedBE',
    'ZhangAge',
  ];
  const methods = ['tsne', 'umap', 'umap_lite'];

  // ---------- Scene setup ----------
  useEffect(() => {
    const scene = new THREE.Scene();
    scene.background = new THREE.Color(0x050b14); // Dark blue-black
    sceneRef.current = scene;

    const camera = new THREE.PerspectiveCamera(
      70,
      window.innerWidth / window.innerHeight,
      0.1,
      2000
    );
    camera.position.set(0, 0, 120);
    cameraRef.current = camera;

    const renderer = new THREE.WebGLRenderer({ antialias: true });
    renderer.setSize(window.innerWidth, window.innerHeight);
    renderer.setPixelRatio(window.devicePixelRatio);
    mountRef.current.appendChild(renderer.domElement);
    rendererRef.current = renderer;

    const controls = new OrbitControls(camera, renderer.domElement);
    controls.enableDamping = true;
    controls.dampingFactor = 0.05;
    controlsRef.current = controls;

    const ambient = new THREE.AmbientLight(0xffffff, 0.8);
    scene.add(ambient);

    const onMouseMove = (event) => {
      const rect = renderer.domElement.getBoundingClientRect();
      mouseNorm.current.x = ((event.clientX - rect.left) / rect.width) * 2 - 1;
      mouseNorm.current.y = -((event.clientY - rect.top) / rect.height) * 2 + 1;
      setCursorPos({ x: event.clientX, y: event.clientY });
    };
    window.addEventListener('mousemove', onMouseMove);

    const animate = () => {
      requestAnimationFrame(animate);
      controls.update();

      if (pointsRef.current) {
        raycaster.current.setFromCamera(mouseNorm.current, camera);
        const intersects = raycaster.current.intersectObject(pointsRef.current);
        if (intersects.length > 0) {
          const i = intersects[0].index;
          const meta = pointsRef.current.userData.meta?.[i];
          if (meta) setHovered(meta);
        } else setHovered(null);
      }

      renderer.render(scene, camera);
    };
    animate();

    window.addEventListener('resize', () => {
      camera.aspect = window.innerWidth / window.innerHeight;
      camera.updateProjectionMatrix();
      renderer.setSize(window.innerWidth, window.innerHeight);
    });

    return () => {
      window.removeEventListener('mousemove', onMouseMove);
      renderer.dispose();
    };
  }, []);

  // ---------- Load data ----------
  useEffect(() => {
    const load = async () => {
      setLoading(true);
      try {
        const res = await fetch(
          `/api/coordinates_bin?analysis=${analysis}&method=${method}&level=20000`
        );
        const buf = await res.arrayBuffer();
        const table = tableFromIPC(new Uint8Array(buf));

        const x = table.getChild('x').toArray();
        const y = table.getChild('y').toArray();
        const z = table.getChild('z').toArray();
        const d = table.getChild('Delta_Age').toArray();
        const metaCols = {};
        for (const k of [
          'GEO',
          'GSM',
          'title',
          'source_name',
          'sex',
          'age',
          'specimen_part',
          'race',
        ]) {
          if (table.getChild(k)) metaCols[k] = table.getChild(k).toArray();
        }

        const minVal = Math.min(...d);
        const maxVal = Math.max(...d);
        setMin(minVal);
        setMax(maxVal);

        const positions = new Float32Array(x.length * 3);
        const colors = new Float32Array(x.length * 3);
        const metaArray = [];

        for (let i = 0; i < x.length; i++) {
          positions.set([x[i], y[i], z[i]], i * 3);
          const norm = (d[i] - minVal) / (maxVal - minVal);
          const color = new THREE.Color(
            COLOR_PALETTE[Math.floor(norm * (COLOR_PALETTE.length - 1))]
          );
          colors.set([color.r, color.g, color.b], i * 3);
          const m = {};
          for (const [k, arr] of Object.entries(metaCols)) m[k] = arr[i];
          m['Delta_Age'] = d[i];
          metaArray.push(m);
        }

        const geometry = new THREE.BufferGeometry();
        geometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));
        geometry.setAttribute('color', new THREE.BufferAttribute(colors, 3));

        const circleTexture = new THREE.TextureLoader().load(
          'data:image/svg+xml;base64,' +
            btoa(
              '<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32"><circle cx="16" cy="16" r="16" fill="white"/></svg>'
            )
        );

        const material = new THREE.PointsMaterial({
          size: 0.5,
          vertexColors: true,
          transparent: true,
          opacity: 0.9,
          map: circleTexture,
          alphaTest: 0.01,
          sizeAttenuation: true,
        });

        if (pointsRef.current) {
          sceneRef.current.remove(pointsRef.current);
          pointsRef.current.geometry.dispose();
          pointsRef.current.material.dispose();
        }

        const points = new THREE.Points(geometry, material);
        points.userData.meta = metaArray;
        sceneRef.current.add(points);
        pointsRef.current = points;
      } catch (e) {
        console.error(e);
      } finally {
        setLoading(false);
      }
    };
    load();
  }, [analysis, method]);

  // ---------- Tooltip position ----------
  const tooltipStyle = {
    position: 'absolute',
    background: 'rgba(30, 30, 30, 0.9)',
    color: 'white',
    padding: '8px 10px',
    borderRadius: '8px',
    fontSize: '12px',
    pointerEvents: 'none',
    zIndex: 100,
    left: Math.min(cursorPos.x + 20, window.innerWidth - 250) + 'px',
    top: Math.min(cursorPos.y + 20, window.innerHeight - 150) + 'px',
    maxWidth: '240px',
    lineHeight: '1.3em',
  };

  return (
    <div className='min-h-screen bg-gradient-to-br from-black via-blue-950 to-slate-900 text-white relative overflow-hidden'>
      <ParticlesBackground />
      <div className='absolute top-0 left-0 right-0 z-50'>
        <ResponsiveNav />
      </div>

      {/* Loading overlay */}
      {loading && (
        <div className='absolute inset-0 flex flex-col items-center justify-center bg-black/70 backdrop-blur-sm z-[80]'>
          <div className='animate-spin rounded-full h-10 w-10 border-4 border-white border-t-transparent mb-4'></div>
          <p className='text-lg font-medium text-white tracking-wide'>Loading...</p>
        </div>
      )}

      {/* Dropdowns */}
      <div className='absolute top-28 left-8 z-[60] flex gap-3'>
        {/* Clock selector */}
        <div className='relative w-48'>
          <button
            onClick={() => setIsAnalysisOpen(!isAnalysisOpen)}
            className='bg-blue-800 hover:bg-blue-900 px-4 py-2 rounded-lg flex items-center justify-between w-full border border-blue-700/50 shadow-lg shadow-blue-900/20'
          >
            <span>{analysis}</span>
            <ChevronDown
              className={`w-4 h-4 transition-transform ${isAnalysisOpen ? 'rotate-180' : ''}`}
            />
          </button>
          {isAnalysisOpen && (
            <div className='absolute top-full left-0 mt-2 bg-blue-900 rounded-lg w-full max-h-60 overflow-y-auto border border-blue-800 shadow-xl z-50'>
              {analyses.map((a) => (
                <button
                  key={a}
                  onClick={() => {
                    setAnalysis(a);
                    setIsAnalysisOpen(false);
                  }}
                  className='block w-full text-left px-4 py-2 hover:bg-blue-800 transition-colors'
                >
                  {a}
                </button>
              ))}
            </div>
          )}
        </div>

        {/* Method selector */}
        <div className='relative w-36'>
          <button
            onClick={() => setIsMethodOpen(!isMethodOpen)}
            className='bg-gray-700 hover:bg-gray-800 px-4 py-2 rounded-lg flex items-center justify-between w-full'
          >
            <span>{method}</span>
            <ChevronDown
              className={`w-4 h-4 transition-transform ${isMethodOpen ? 'rotate-180' : ''}`}
            />
          </button>
          {isMethodOpen && (
            <div className='absolute top-full left-0 mt-2 bg-gray-800 rounded-lg w-full max-h-60 overflow-y-auto'>
              {methods.map((m) => (
                <button
                  key={m}
                  onClick={() => {
                    setMethod(m);
                    setIsMethodOpen(false);
                  }}
                  className='block w-full text-left px-4 py-2 hover:bg-gray-700'
                >
                  {m}
                </button>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Scene */}
      <div ref={mountRef} className='w-full h-screen' />

      {/* Tooltip */}
      {hovered && !loading && (
        <div style={tooltipStyle}>
          {Object.entries(hovered)
            .filter(([_, v]) => v && v !== '')
            .slice(0, 8)
            .map(([k, v]) => (
              <p key={k}>
                <span className='font-semibold'>{k}: </span>
                {String(v)}
              </p>
            ))}
        </div>
      )}

      {/* Color scale */}
      <div className='absolute bottom-30 right-10 z-40'>
        <ColorBar min={min} max={max} colors={COLOR_PALETTE} />
      </div>

      <Footer />
    </div>
  );
}
