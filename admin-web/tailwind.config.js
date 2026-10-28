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
          deep: '#063D2E',
          mint: '#A7E8D2',
          light: '#E6F4EF',
          soft: '#D0EDE3',
        },
        surface: {
          DEFAULT: '#F2F7F4',
          subtle: '#E8F0EC',
          card: '#FFFFFF',
          overlay: 'rgba(242,247,244,0.95)',
        },
        textMain: '#12352E',
        textMuted: '#6B7F78',
        textLight: '#9AADA7',
        accentGold: '#C9A96E',
        accentAmber: '#D97706',
        statusGreen: '#059669',
        statusRed: '#DC2626',
        statusAmber: '#D97706',
        statusBlue: '#2563EB',
        statusPurple: '#7C3AED',
      },
      fontFamily: {
        sans: ['Plus Jakarta Sans', 'system-ui', 'sans-serif'],
        mono: ['JetBrains Mono', 'Menlo', 'Monaco', 'monospace'],
      },
      boxShadow: {
        '2xs': '0 1px 2px 0 rgba(0, 0, 0, 0.03)',
        'xs': '0 1px 2px 0 rgba(11,93,75,0.05)',
        'card': '0 1px 3px 0 rgba(11,93,75,0.08), 0 1px 2px -1px rgba(11,93,75,0.08)',
        'elevated': '0 4px 6px -1px rgba(11,93,75,0.10), 0 2px 4px -2px rgba(11,93,75,0.10)',
        'modal': '0 20px 25px -5px rgba(18,53,46,0.15), 0 8px 10px -6px rgba(18,53,46,0.10)',
        'glass': '0 8px 30px 0 rgba(11, 93, 75, 0.07)',
        'glass-hover': '0 14px 38px 0 rgba(11, 93, 75, 0.13)',
        'glow-mint': '0 0 24px -2px rgba(167, 232, 210, 0.55)',
        'glow-forest': '0 10px 28px -4px rgba(11, 93, 75, 0.35)',
      },
      borderRadius: {
        'xl': '0.75rem',
        '2xl': '1rem',
        '3xl': '1.5rem',
        '4xl': '2rem',
      },
      animation: {
        'fade-in': 'fadeIn 0.25s cubic-bezier(0.16, 1, 0.3, 1)',
        'slide-up': 'slideUp 0.3s cubic-bezier(0.16, 1, 0.3, 1)',
        'scale-in': 'scaleIn 0.2s cubic-bezier(0.16, 1, 0.3, 1)',
        'pulse-slow': 'pulseSlow 3s ease-in-out infinite',
        'shimmer': 'shimmer 2.2s linear infinite',
      },
      keyframes: {
        fadeIn: { '0%': { opacity: '0' }, '100%': { opacity: '1' } },
        slideUp: { '0%': { opacity: '0', transform: 'translateY(10px)' }, '100%': { opacity: '1', transform: 'translateY(0)' } },
        scaleIn: { '0%': { opacity: '0', transform: 'scale(0.96)' }, '100%': { opacity: '1', transform: 'scale(1)' } },
        pulseSlow: {
          '0%, 100%': { opacity: '1', transform: 'scale(1)' },
          '50%': { opacity: '0.6', transform: 'scale(1.04)' },
        },
        shimmer: {
          '0%': { backgroundPosition: '-200% 0' },
          '100%': { backgroundPosition: '200% 0' },
        },
      },
    },
  },
  plugins: [],
}
