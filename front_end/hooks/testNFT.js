import { useContract } from '@starknet-react/core'
import { Abi } from 'starknet'

import TestNFT from '../abi/TestNFT.json'

export function useTestNFTContract() {
  return useContract({
    abi: TestNFT.abi,
    address: '0x043cc9735efbb2b54ea79009dca04555f9e4377344bbd75a1c98f00378994037',
  })
}