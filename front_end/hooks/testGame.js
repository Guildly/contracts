import { useContract } from '@starknet-react/core'
import deploymentsConfig from '../deployments-config.json'

import TestGame from '../abi/TestNFT.json'

export function useTestGameContract() {
    return useContract({
      abi: TestGame.abi,
      address: deploymentsConfig["networks"]["goerli"]["test_game_contract"],
    })
  }