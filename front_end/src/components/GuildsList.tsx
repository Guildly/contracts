import styles from '../styles/components/GuildsList.module.css'
import {
    useStarknetCall
} from '@starknet-react/core'
import {
    useCallback,
    useState
} from 'react'
import { useGuildFactoryContract } from '~/hooks/guildFactory'

export const GuildsList = () => {
    const { contract } = useGuildFactoryContract()
    const { data, loading, error } = useStarknetCall({
        contract,
        method: 'get_guilds',
        args: undefined,
    })

    return (
        <div>
            {data?.map((fund, index) =>
                <>
                    <div className={styles.input} key={index}>
                        <p>Guild: {fund}</p>
                    </div>
                </>
            )}
        </div>
    )
}