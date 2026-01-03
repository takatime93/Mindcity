/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        // Era colors
        'stone-age': '#8B4513',
        'ancient': '#F5F5DC',
        'medieval': '#808080',
        'renaissance': '#FFD700',
        'industrial': '#4A4A4A',
        'modern': '#C0C0C0',
        'future': '#00FFFF',
        // Category colors
        'philosophy': '#9333EA',
        'technical': '#3B82F6',
        'creative': '#F97316',
        'science': '#22C55E',
        'personal': '#EAB308',
        'general': '#6B7280',
      },
      animation: {
        'pulse-slow': 'pulse 3s cubic-bezier(0.4, 0, 0.6, 1) infinite',
        'bounce-gentle': 'bounce 2s infinite',
      }
    },
  },
  plugins: [],
}
