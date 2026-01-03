/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  // Enable static export for PWA
  output: 'export',
  images: {
    unoptimized: true
  }
}

module.exports = nextConfig
