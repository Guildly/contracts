import styles from '../styles/Guilds.module.css'
import type { NextPage } from 'next'
import { CreateGuild } from '~/components/CreateGuild'
import { GuildsList } from '~/components/GuildsList'

const GuildsPage: NextPage = () => {

    return (
        <div className={styles.container}>
            <h2>Create Guild</h2>
            <CreateGuild />
            <h2>Guilds</h2>

        </div>
    )
}

export default GuildsPage
