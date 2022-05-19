import { useContract } from '@starknet-react/core'
import { Abi } from 'starknet'

import Counter from '../abi/counter.json'

export function useCounterContract() {
  return useContract({
    abi: Counter,
    address: '0x036486801b8f42e950824cba55b2df8cccb0af2497992f807a7e1d9abd2c6ba1',
  })
}