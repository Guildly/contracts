import { useState } from 'react'
import { useRouter } from 'next/router'
import { useDisplayName } from '../../hooks/starknet';
import styles from '../../styles/Managing.module.css'
import Header from '../../components/header';
import { useStarknet } from '@starknet-react/core';
import ShortTextInput from '../../components/input';
import Dropdown from '../../components/dropdown';

export default function Members() {
    const router = useRouter()
    const { pid } = router.query
    const { account } = useStarknet()
    const [addAddress, setAddAddress] = useState()
    const [addRole, setAddRole] = useState(0)


    return (
        <div className="background">
            <Header/>

            <div className={styles.box}>
                <h1 className={styles.title}>Managing {pid}</h1>
                <h2 className={styles.subtitle}>Add Member</h2>
                <div>
                    <ShortTextInput content={addAddress} setContent={setAddAddress} label="New Member Address" />
                    <Dropdown onChange={setAddRole} />
                    <button className={styles.button_normal}>
                        <p>Add Member</p>
                    </button>
                </div>
                <h2 className={styles.subtitle}>Permissions</h2>
                <div>
                    <table>
                        <thead>
                            <tr className={styles.table_header}>
                                <th className={styles.table_first_item}>Contract</th>
                                <th>Function</th>
                                <th>Data</th>
                            </tr>
                        </thead>
                        <tbody>
                            {/* {data? data.map((guild) => 
                                <GuildBox key={guild} guild={guild} />) 
                            : undefined} */}
                            <tr className={styles.table_body}>
                                <td className={styles.table_first_item}>Eykar</td>
                                <td>Battle</td>
                                <td>-</td>
                            </tr>
                        </tbody>
                    </table>
                    <button className={styles.button_normal}>
                        <svg className={styles.icon} fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-11a1 1 0 10-2 0v2H7a1 1 0 100 2h2v2a1 1 0 102 0v-2h2a1 1 0 100-2h-2V7z" clipRule="evenodd"></path></svg>
                    </button>
                </div>
            </div>
        </div>
    )
}