import { useContract } from '@starknet-react/core'
import deploymentsConfig from '../deployments-config.json'

import TestNFT from '../abi/TestNFT.json'

export function useTestNFTContract() {
  return useContract({
    abi: TestNFT,
    address: deploymentsConfig["networks"]["goerli"]["test_nft"],
  })
}