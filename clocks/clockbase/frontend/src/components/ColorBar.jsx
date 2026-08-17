import React from 'react';

const ColorBar = ({ min, max, colors }) => {
  // Generate gradient string for CSS
  const gradient = colors.map((color, index) => {
    const percent = (index / (colors.length - 1)) * 100;
    return `${color} ${percent}%`;
  }).join(', ');

  // Calculate label positions
  const numLabels = 5; // Number of labels (e.g., min, max, and 3 intermediates)
  const labels = [];
  for (let i = 0; i < numLabels; i++) {
    const value = min + (i / (numLabels - 1)) * (max - min);
    const percent = (i / (numLabels - 1)) * 100;
    labels.push({ value: value.toFixed(2), percent });
  }

  return (
    <div className="relative w-64 h-6 bg-gray-800 rounded flex items-center">
      {/* Gradient bar */}
      <div
        className="w-full h-full rounded"
        style={{
          background: `linear-gradient(to right, ${gradient})`,
        }}
      />
      {/* Labels */}
      <div className="absolute w-full h-full flex justify-between">
        {labels.map((label, index) => (
          <span
            key={index}
            className="text-xs text-white"
            style={{
              position: 'absolute',
              left: `${label.percent}%`,
              transform: 'translateX(-50%)',
              top: '100%',
              marginTop: '4px',
            }}
          >
            {label.value}
          </span>
        ))}
      </div>
    </div>
  );
};

export default ColorBar;