import '../styles/globals.css'
import type { AppProps } from 'next/app'
import NextHead from 'next/head'
import { InjectedConnector, StarknetProvider } from '@starknet-react/core'
import { Navbar } from '~/components/Navbar'

function MyApp({ Component, pageProps }: AppProps) {
  const connectors = [new InjectedConnector()]

  return (
    <StarknetProvider autoConnect connectors={connectors}>
      <NextHead>
        <title>Game Guilds</title>
      </NextHead>
      <Navbar />
      <Component {...pageProps} />
    </StarknetProvider>
  )
}

export default MyApp
