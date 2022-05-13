import { useContract } from '@starknet-react/core'
import { Abi } from 'starknet'

import GuildsFactoryAbi from '~/abi/erc20.json'
import deploymentsConfig from "../../deployments-config.json"


export function useGuildFactoryContract() {
    const address = deploymentsConfig["networks"]["goerli"]["fund_factory"]
    return useContract({
        abi: GuildsFactoryAbi as Abi,
        address: address,
    })
}
