/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        nepal: {
          red: '#DC143C',
          'red-dark': '#B01030',
          'red-light': '#F4364F',
          blue: '#003893',
          'blue-dark': '#002A6E',
          'blue-light': '#1A5BB5',
        },
        dashboard: {
          bg: '#0F172A',
          card: '#1E293B',
          'card-hover': '#2D3B50',
          border: '#334155',
          text: '#E2E8F0',
          'text-muted': '#94A3B8',
        },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', '-apple-system', 'sans-serif'],
      },
    },
  },
  plugins: [],
}
