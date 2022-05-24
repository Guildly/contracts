import { useRouter } from 'next/router'
import { useDisplayName } from '../../hooks/starknet';
import styles from '../../styles/Members.module.css'
import Header from '../../components/header';
import { useStarknet } from '@starknet-react/core';

export default function Members() {
    const router = useRouter()
    const { pid } = router.query
    const { account } = useStarknet()
    const name = useDisplayName(account)


    return (
        <div className="background">
            <Header/>

            <div className={styles.box}>
                <h1 className={styles.title}>Members {pid}</h1>
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
                                <td><button>Update Role</button></td>
                                <td className={styles.table_last_item}><button>Remove</button></td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    )
}