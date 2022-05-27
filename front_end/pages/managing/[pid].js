import { useState, useMemo, useEffect } from 'react'
import { useRouter } from 'next/router'
import { useDisplayName } from '../../hooks/starknet';
import styles from '../../styles/Managing.module.css'
import Header from '../../components/header';
import { 
    useStarknet, 
    useStarknetInvoke,
    useStarknetCall,
    useStarknetTransactionManager 
} from '@starknet-react/core';
import ShortTextInput from '../../components/input';
import Dropdown from '../../components/dropdown';
import { Main } from '../../features/Main';
import { useGuildsContract, useShareCertificate } from '../../hooks/guilds';
import Link from 'next/link';

export const getGuild = (pid) => {
    const { supportedGuilds } = Main()
    return supportedGuilds.find(
      guild => guild.slug === pid
    )
}

export default function Managing() {

    const router = useRouter()
    const { pid } = router.query

    const guild = getGuild(pid)

    const { contract: guildContract } = useGuildsContract(guild? guild.address: 0);

    const { 
        data: whitelistMembersData, 
        loading: whitelistMembersLoading, 
        invoke: whitelistMembersInvoke 
    } = useStarknetInvoke(
        { 
            contract: guildContract,
             method: 'whitelist_members' 
        }
    );

    const {data: isPermissionsInitialized} = useStarknetCall(
        { 
            contract: guildContract, 
            method: 'is_permissions_initialized', 
            args: [] 
        }
    )

    const { account } = useStarknet()
    const [addAddress, setAddAddress] = useState()
    const [addRole, setAddRole] = useState(0)

    const [whitelistMemberList, setWhitelistMemberList] = useState([
        { whitelistMember: "" }
    ])

    const handleWhitelistMemberAdd = () => {
        setWhitelistMemberList([...whitelistMemberList, { whitelistMember: "" }])
    }

    const { transactions } = useStarknetTransactionManager()

    useEffect(() => {
        for (const transaction of transactions)
          if (transaction.transactionHash === data) {
            if (transaction.status === 'ACCEPTED_ON_L2'
              || transaction.status === 'ACCEPTED_ON_L1')
              setMinted(true);
          }
    }, [whitelistMembersData])

    const roles = ["Member", "Admin", "Owner"]

    const name = useDisplayName(account);

    const whitelistArray = [addAddress];

    const roleArray = [addRole];

    return (
        <div className="background">
            <Header/>
            <div className="content">
                <div className={styles.box}>
                    <h1 className={styles.title}>Managing {guild? guild.name : undefined}</h1>

                    <h2 className={styles.subtitle}>Join Requests</h2>

                    <div>
                    <table className={styles.table}>
                            <thead>
                                <tr>
                                    <th>Account</th>
                                    <th>Message</th>
                                </tr>
                            </thead>
                            <tbody>
                                {/* {data? data.map((guild) => 
                                    <GuildBox key={guild} guild={guild} />) 
                                : undefined} */}
                                <tr>
                                    <td>{useDisplayName(account)}</td>
                                    <td>I am an active player and can contribute x and y</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>

                    <h2 className={styles.subtitle}>Whitelist Members</h2>
                    {whitelistMemberList.map((input, index) =>
                    <>
                        <div className={styles.member_row} key={index}>
                            <ShortTextInput content={addAddress} setContent={setAddAddress} label="Address" />
                            <Dropdown value={addRole} options={roles} onChange={setAddRole} />
                        </div>
                        {whitelistMemberList.length - 1 === index && whitelistMemberList.length < 3 &&
                            (
                                <button className={styles.add_member_button} onClick={handleWhitelistMemberAdd}>
                                    <svg fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-11a1 1 0 10-2 0v2H7a1 1 0 100 2h2v2a1 1 0 102 0v-2h2a1 1 0 100-2h-2V7z" clipRule="evenodd"></path></svg>
                                </button>
                            )}
                    </>
                    )}
                    <div>
                        <button 
                            className={styles.button}
                            onClick={() => 
                                whitelistMembersInvoke({
                                    args: [
                                        whitelistArray,
                                        roleArray,
                                    ],
                                    metadata: { 
                                        method: 'whitelist_members', 
                                        message: 'whitelist members to a guild' 
                                    }
                                })
                            }
                        >
                            <p>Whitelist Members</p>
                        </button>
                    </div>
                    <h2 className={styles.subtitle}>Permissions</h2>
                    {isPermissionsInitialized == 1 ? (
                        <div>
                            <table className={styles.table}>
                                <thead>
                                    <tr>
                                        <th>Contract</th>
                                        <th>Function</th>
                                        <th>Data</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {/* {data? data.map((guild) => 
                                        <GuildBox key={guild} guild={guild} />) 
                                    : undefined} */}
                                    <tr>
                                        <td>Eykar</td>
                                        <td>Battle</td>
                                        <td>-</td>
                                    </tr>
                                </tbody>
                            </table>
                            <button className={styles.button}>
                                <div className={styles.proposal}>
                                    <svg className={styles.icon} stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path d="M12 14l9-5-9-5-9 5 9 5z"></path><path d="M12 14l6.16-3.422a12.083 12.083 0 01.665 6.479A11.952 11.952 0 0012 20.055a11.952 11.952 0 00-6.824-2.998 12.078 12.078 0 01.665-6.479L12 14z"></path><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 14l9-5-9-5-9 5 9 5zm0 0l6.16-3.422a12.083 12.083 0 01.665 6.479A11.952 11.952 0 0012 20.055a11.952 11.952 0 00-6.824-2.998 12.078 12.078 0 01.665-6.479L12 14zm-4 6v-7.5l4-2.222"></path></svg>
                                    <p>Create Proposal</p>
                                </div>
                            </button>
                        </div>
                        ):
                        (
                            <div>
                                <p className={styles.text}>Permissions have not been initialized</p>
                                <Link href={guild ? "/permissions/"+guild.slug : "/permissions/0"}>
                                    <button className={styles.button}>
                                        <div className={styles.proposal}>
                                            <svg className={styles.icon} fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z"></path></svg>
                                            <p>Set Permissions</p>
                                        </div>
                                    </button>
                                </Link>
                            </div>
                        )
                    }
                </div>
            </div>
        </div>
    )
}