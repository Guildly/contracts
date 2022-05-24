import Header from '../components/header';
import styles from '../styles/Manage.module.css'
import { useState, useRef } from "react";
import ShortTextInput from "../components/input";
import Spinner from "../components/spinner";
import Link from 'next/link'
import { useStarknet } from '@starknet-react/core'
import { useGuildsContract } from '../hooks/guilds';
import { Main } from '../features/Main';

export default function Manage() {

    const { supportedGuilds } = Main()

    // const guild = "0x0544ca787ac6f35fe1196badf06c4b247ea04ad3da10035d021ef05af86708c0"

    const { account } = useStarknet();
    // const { contract: guildContract } = useGuildsContract(guild)
    // const { data } = useGuildsManaged(account);

    return(
        <div className="background">
            <Header highlighted={"manage"} />
            <div className={styles.box}>
                <div className={styles.header}>
                    <h1 className={styles.title}>Guilds Your Managing</h1>
                </div>
                <div className={styles.manage_options}>
                    <table className={styles.table}>
                        <thead>
                            <tr>
                                <th>Guild</th>
                                <th>Members</th>
                                <th>Proposals</th>
                                <th></th>
                            </tr>
                        </thead>
                        <tbody>
                            {supportedGuilds? supportedGuilds.map((guild, index) => 
                                <tr 
                                    key={index}
                                >
                                    <td>{guild.name}</td>
                                    <td>47 <Link href="/members/0">(See List)</Link></td>
                                    <td>2</td>
                                    <td>
                                        <Link href={"/managing/"+guild.slug}>
                                            <div className={styles.button_normal}>
                                                <p>See More</p>
                                            </div>
                                        </Link>
                                    </td>
                                </tr>
                                ) 
                                : undefined}
                        </tbody>
                    </table>
                    {/* <p className={styles.option_title}>
                        Guild
                    </p>
                    <p className={styles.option_title}>
                        Governance
                    </p>
                    <p className={styles.option_title}>
                        Permissions
                    </p> */}
            </div>
            </div>
            <div className={styles.box}>
                <div className={styles.header}>
                    <h1 className={styles.title}>Governace</h1>
                </div>
            </div>
        </div>
    )
}