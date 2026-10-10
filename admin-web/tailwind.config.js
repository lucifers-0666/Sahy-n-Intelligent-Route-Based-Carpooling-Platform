/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        forest: {
          DEFAULT: '#0B5D4B',
          dark: '#084C3A',
          mint: '#A7E8D2',
          light: '#E6F4EF',
        },
        surface: {
          DEFAULT: '#F2F7F4',
          subtle: '#E8F0EC',
        },
        textMain: '#12352E',
        textMuted: '#6B7F78',
        accentGold: '#C9A96E',
      },
      fontFamily: {
        sans: ['Plus Jakarta Sans', 'system-ui', 'sans-serif'],
      },
    },
  },
  plugins: [],
}
