/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  // Enable static export for PWA
  output: 'export',
  // GitHub Pages deploys to /Mindcity/ subdirectory
  basePath: '/Mindcity',
  assetPrefix: '/Mindcity/',
  images: {
    unoptimized: true
  }
}

module.exports = nextConfig
