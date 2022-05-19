/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  webpack: (config, options) => {
    config.module.rules.push({
      test: /\.txt/,
      type: "asset/source",
    })
    return config
  },
}

module.exports = nextConfig
