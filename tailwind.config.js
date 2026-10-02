/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      fontFamily: {
        mono: ['"JetBrains Mono"', 'ui-monospace', 'SFMono-Regular', 'Menlo', 'Monaco', 'Consolas', '"Liberation Mono"', '"Courier New"', 'monospace'],
      },
      colors: {
        terminal: {
          bg: '#000000',
          card: '#0a0a0a',
          border: '#262626',
          borderSubtle: '#171717',
          text: '#e5e5e5',
          muted: '#737373',
          dim: '#404040',
          accent: '#ffffff',
          ready: '#22c55e',
          busy: '#eab308',
          offline: '#6b7280',
        },
      },
      animation: {
        blink: 'blink 1s step-end infinite',
      },
      keyframes: {
        blink: {
          '0%, 100%': { opacity: '1' },
          '50%': { opacity: '0' },
        },
      },
    },
  },
  plugins: [],
}
