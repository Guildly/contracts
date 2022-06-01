import { useRouter } from 'next/router'
import { useDisplayName } from '../../hooks/starknet';
import styles from '../../styles/Members.module.css'
import Header from '../../components/header';
import { 
    useStarknet,
    useStarknetCall,
    useStarknetInvoke
} from '@starknet-react/core';
import { Main } from '../../features/Main';
import { 
    useGuildsContract,
    useGuildCertificate
} from '../../hooks/guilds';

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

    const { contract: guildCertificateContract} = useGuildCertificate()

    const { data: certificateIdResult } = useStarknetCall({
        contract: guildCertificateContract,
        method: "get_certificate_id",
        args: [account, guild ? guild.address : 0]
    })

    const { data: roleResult } = useStarknetCall({
        contract: guildCertificateContract, 
        method: "get_role",
        args: [certificateIdResult]
    })

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

    const { 
        data: updateRoleData, 
        loading: updateRoleLoading, 
        invoke: updateRoleInvoke 
    } = useStarknetInvoke(
        { 
            contract: guildContract,
            method: 'update_role' 
        }
    );

    const membersArray = [0]

    const role = 2;

    console.log(account, role)

    return (
        <div className="background">
            <Header/>

            <div className={styles.box}>
                <h1 className={styles.title}>Members of {guild ? guild.name : "..."}</h1>
                <div>
                    <table className={styles.table}>
                        <thead>
                            <tr>
                                <th>Member</th>
                                <th>Role</th>
                                <th></th>
                                <th></th>
                            </tr>
                        </thead>
                        <tbody>
                            {/* {data? data.map((guild) => 
                                <GuildBox key={guild} guild={guild} />) 
                            : undefined} */}
                            <tr>
                                <td>{name}</td>
                                <td>{roleResult ? roleResult : '-'}</td>
                                <td>
                                    <button 
                                        className={styles.button}
                                        onClick={() => 
                                            updateRoleInvoke({
                                                args: [account, role],
                                                metadata: {
                                                    method: "update role",
                                                    message: "update role of member"
                                                }
                                            })
                                        }
                                    >
                                        Update Role
                                    </button>
                                </td>
                                <td>
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