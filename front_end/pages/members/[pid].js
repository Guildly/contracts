import { useRouter } from 'next/router'
import { useDisplayName } from '../../hooks/starknet';
import styles from '../../styles/Members.module.css'
import Header from '../../components/header';
import { 
    useStarknet,
    useStarknetInvoke
} from '@starknet-react/core';
import { Main } from '../../features/Main';
import { useGuildsContract } from '../../hooks/guilds';

export const getGuild = (pid) => {
    const { supportedGuilds } = Main()
    return supportedGuilds.find(
      guild => guild.slug === pid
    )
}

export default function Members() {
    const router = useRouter()
    const { pid } = router.query
    const { account } = useStarknet()
    const name = useDisplayName(account)

    const guild = getGuild(pid)

    const { contract: guildContract } = useGuildsContract(guild? guild.address: 0);

    const { 
        data: removeMembersData, 
        loading: removeMembersLoading, 
        invoke: removeMembersInvoke 
    } = useStarknetInvoke(
        { 
            contract: guildContract,
             method: 'remove_members' 
        }
    );

    const membersArray = [0]

    return (
        <div className="background">
            <Header/>

            <div className={styles.box}>
                <h1 className={styles.title}>Members of {guild ? guild.name : "..."}</h1>
                <div>
                    <table>
                        <thead>
                            <tr className={styles.table_header}>
                                <th className={styles.table_first_item}>Member</th>
                                <th>Role</th>
                                <th></th>
                                <th></th>
                            </tr>
                        </thead>
                        <tbody>
                            {/* {data? data.map((guild) => 
                                <GuildBox key={guild} guild={guild} />) 
                            : undefined} */}
                            <tr className={styles.table_body}>
                                <td>{name}</td>
                                <td>Member</td>
                                <td>
                                    <button className={styles.button}>
                                        Update Role
                                    </button>
                                </td>
                                <td className={styles.table_last_item}>
                                    <button 
                                        className={styles.button}
                                        onClick={() => 
                                            removeMembersInvoke({
                                                args: [
                                                    membersArray,
                                                ],
                                                metadata: { 
                                                    method: 'remove_members', 
                                                    message: 'remove members from a guildd' 
                                                }
                                            })
                                        }
                                    >
                                        Remove
                                    </button>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    )
}