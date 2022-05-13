import { useStarknetCall } from '@starknet-react/core'
import type { NextPage } from 'next'
import { useMemo } from 'react'
import { toBN } from 'starknet/dist/utils/number'
import { TransactionList } from '~/components/TransactionList'
import { useCounterContract } from '~/hooks/counter'

const Home: NextPage = () => {

  return (
    <div>
      <h2>NFTs</h2>
    </div>
  )
}

export default Home
