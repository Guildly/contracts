import { useContract } from '@starknet-react/core'
import GuildAccount from '../abi/GuildAccount.json'
import GuildCertificate from '../abi/GuildCertificate.json'
import TestNFT from '../abi/TestNFT.json'
import deploymentsConfig from '../deployments-config.json'


export function useGuildsContract(contract) {
  const output = contract.toString(16);
  return useContract({
    abi: GuildAccount,
    address: /^0x/.test(output) ? output : "0x" + output,
  })
}

export function useGuildCertificate() {
  return useContract({
    abi: GuildCertificate,
    address: deploymentsConfig["networks"]["goerli"]["guild_certificate"],
  })
}