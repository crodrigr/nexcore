// Minimal ambient module declaration to silence TypeScript when Chart.js
// is not yet installed. Prefer installing `chart.js` in the frontend
// project to get full types: `npm install chart.js`.

declare module 'chart.js/auto' {
  const value: any;
  export default value;
}
