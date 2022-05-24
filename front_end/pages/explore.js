import Header from '../components/header';
import styles from '../styles/Explore.module.css'
import { useState, useRef } from "react";
import ShortTextInput from "../components/input";
import Spinner from "../components/spinner";
import Link from 'next/link'
import { useStarknet } from '@starknet-react/core'

export default function Manage() {

    const { account } = useStarknet();
    // const { data } = useGuildsManaged(account);
    const [searchTerm, setSearchTerm] = useState()

    const searchIcon = 
        <>
            <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z">
                </path>
            </svg>
        </>

    return(
        <div className="background">
            <Header highlighted={"explore"} />
            <div className={styles.box}>
                <div className={styles.header}>
                    <h1 className={styles.title}>Explore</h1>
                    <ShortTextInput content={searchTerm} setContent={setSearchTerm} label="Search" icon={searchIcon}/>
                </div>
                <div>
                    <table>
                        <thead>
                            <tr className={styles.table_header}>
                                <th className={styles.table_first_item}>Guild</th>
                                <th>Members</th>
                                <th>Proposals</th>
                                <th></th>
                            </tr>
                        </thead>
                        <tbody>
                            {/* {data? data.map((guild) => 
                                <GuildBox key={guild} guild={guild} />) 
                            : undefined} */}
                            <tr className={styles.table_body}>
                                <td>Titans Of The Dark Circle</td>
                                <td>47 <Link href="/members/0">(See List)</Link></td>
                                <td>2</td>
                                <td className={styles.table_last_item}>
                                    <button className={styles.button_normal}>See More</button>
                                </td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    )
}