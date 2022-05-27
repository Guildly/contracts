import { useState, useMemo, useEffect } from 'react'
import styles from '../../styles/Permissions.module.css';
import { useRouter } from 'next/router';
import Header from '../../components/header';
import { Main } from '../../features/Main';
import { useGuildsContract } from '../../hooks/guilds';
import { 
    useStarknet, 
    useStarknetInvoke,
    useStarknetCall,
    useStarknetTransactionManager 
} from '@starknet-react/core';
import ShortTextInput from '../../components/input';

export const getGuild = (pid) => {
    const { supportedGuilds } = Main()
    return supportedGuilds.find(
      guild => guild.slug === pid
    )
}

export default function Permissions() {

    const router = useRouter()
    const { pid } = router.query

    const guild = getGuild(pid)

    const { contract: guildContract } = useGuildsContract(guild? guild.address: 0);

    const { 
        data: initializePermissionsData, 
        loading: initializePermissionsLoading, 
        invoke: initializePermissionsInvoke 
    } = useStarknetInvoke(
        { 
            contract: guildContract,
             method: 'initialize_permissions' 
        }
    );

    const [permissionsList, setPermissionsList] = useState([
        { permission: "" }
    ])

    const handlePermissionAdd = () => {
        setPermissionsList([...permissionsList, { permission: "" }])
    }

    const [addAddress, setAddAddress] = useState("")
    const [addSelector, setAddSelector] = useState("")

    console.log(addAddress, addSelector)

    return(
        <div className="background">
            <Header/>
            <div className="content">
                <div className={styles.box}>
                    <h1 className={styles.title}>Set Permissions</h1>
                    {permissionsList.map((input, index) =>
                    <>
                        <div className={styles.permission_row} key={index}>
                            <ShortTextInput content={addAddress} setContent={setAddAddress} label="Address" />
                            <ShortTextInput content={addSelector} setContent={setAddSelector} label="Selector" />
                        </div>
                        {permissionsList.length - 1 === index && permissionsList.length < 3 &&
                            (
                                <button className={styles.add_permission_button} onClick={handlePermissionAdd}>
                                    <svg fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-11a1 1 0 10-2 0v2H7a1 1 0 100 2h2v2a1 1 0 102 0v-2h2a1 1 0 100-2h-2V7z" clipRule="evenodd"></path></svg>
                                </button>
                            )}
                    </>
                    )}
                    <div>
                        <button 
                            className={styles.button}
                            onClick={() => 
                                initializePermissionsInvoke({
                                    args: [
                                        addAddress,
                                        addSelector,
                                    ],
                                    metadata: { 
                                        method: 'initialize_permissions', 
                                        message: 'initialize permissions of a guild' 
                                    }
                                })
                            }
                        >
                            <p>initialize Permissions</p>
                        </button>
                    </div>
                </div>
            </div>
        </div>

    )
}