import { useContract } from '@starknet-react/core'
import deploymentsConfig from '../deployments-config.json'

import TestGame from '../abi/GameContract.json'

export function useTestGameContract() {
    return useContract({
      abi: TestGame,
      address: deploymentsConfig["networks"]["goerli"]["test_game_contract"],
    })
  }