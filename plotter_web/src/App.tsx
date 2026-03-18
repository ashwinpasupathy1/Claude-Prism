import { useState } from 'react';
import { PlotterChart } from './PlotterChart';

export default function App() {
  const [chartType] = useState('bar');
  const [kw] = useState({ excel_path: '', title: 'Claude Plotter' });

  return (
    <div style={{ fontFamily: 'Arial, sans-serif', height: '100vh', display: 'flex', flexDirection: 'column' }}>
      <header style={{ padding: '8px 16px', background: '#2274A5', color: 'white' }}>
        <h1 style={{ margin: 0, fontSize: 18 }}>Claude Plotter</h1>
      </header>
      <main style={{ flex: 1 }}>
        <PlotterChart chartType={chartType} kw={kw} />
      </main>
    </div>
  );
}
