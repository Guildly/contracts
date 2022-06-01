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
import { MultipleRowInput } from '../../components/input';
import { toBN } from 'starknet/dist/utils/number';
import TransactionDialog from '../../components/transactionDialog';
import { getSelectorFromName } from "starknet/dist/utils/hash";
import { validate256BitHash } from '../../hooks/starknet';

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
        { 
            to: "" ,
            selector: ""
        }
    ])

    const handlePermissionAdd = () => {
        setPermissionsList([...permissionsList, 
            { 
                to: "",
                selector: ""
            }
        ])
    }

    const handlePermissionRemove = (index) => {
        const rows = [...permissionsList];
        rows.splice(index, 1);
        setPermissionsList(rows);
    }

    const handleChange = (index, evnt) => {
        const { name, value } = evnt.target;
        const list = [...permissionsList];
        list[index][name] = value
        setPermissionsList(list);
    }

    const [initialized, setInititialized] = useState(false)

    const [
        initializePermissionsDialogToggled, 
        setInitializePermissionsDialogToggled
    ] = useState(false)

    const handleInitializePermissionsSubmit = () => {
        const formattedPermissionsList = []
        for (var i=0; i<permissionsList.length; i++) {
            formattedPermissionsList[i] = {
                to: toBN(permissionsList[i].to),
                selector: getSelectorFromName(permissionsList[i].selector)
            }
        }
        initializePermissionsInvoke({
            args: [formattedPermissionsList],
            metadata: { 
                method: 'initialize_permissions', 
                message: 'initialize permissions of a guild' 
            }
        })
        setInitializePermissionsDialogToggled(true)
    }

    let valid = true

    const [errors, setErrors] = useState({})

    const newErrors = {}

    useEffect(() => {
        for (var i=0; i<permissionsList.length; i++) {
            console.log(permissionsList[i].to)
            console.log(validate256BitHash(permissionsList[i].to))
            if (validate256BitHash(permissionsList[i].to)) {
                valid = false
                message = "Must be a valid 256 bit hash"
                newErrors[i] = message
            }
        }
        if (!valid) setErrors(newErrors)
    }, [permissionsList])

    const { transactions } = useStarknetTransactionManager()

    useEffect(() => {
        for (const transaction of transactions)
          if (transaction.transactionHash === initializePermissionsData) {
            if (transaction.status === 'ACCEPTED_ON_L2'
              || transaction.status === 'ACCEPTED_ON_L1')
              setInititialized(true);
          }
    }, [initializePermissionsData, transactions])

    return(
        <div className="background">
            <Header/>
            <div className="content">
            
            {initializePermissionsDialogToggled ? 
                <TransactionDialog
                    title={"Initialize Permissions"}
                    description={"Initialize guild permissions"}
                    close={() => setInitializePermissionsDialogToggled(false)}
                    loading={initializePermissionsLoading}
                    value={initialized}
                    setValue={setInititialized}
                /> : null
            }
                <div className={styles.box}>
                    <h1 className={styles.title}>Set Permissions</h1>
                    {permissionsList.map((permission, index) => {
                        const {to, selector} = permission;
                        return(
                        <>
                            <div className={styles.permission_row} key={index}>
                                <div className={styles.permission_inputs}>
                                    <MultipleRowInput value={to} onChange={(evnt)=>handleChange(index,evnt)} name="to" label="Contract Address" errors={errors}/>
                                    <MultipleRowInput value={selector} onChange={(evnt)=>handleChange(index,evnt)} name="selector" label="Selector Name" />
                                </div>
                                {
                                    (permissionsList.length!==1 && index!==0)? 
                                    <div className={styles.button_area}>
                                        <button className={styles.action_button} onClick={handlePermissionRemove}>
                                            <svg className={styles.button_icon} fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 12H9m12 0a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                                        </button>
                                    </div>
                                    : null
                                }
                            </div>
                            {
                                permissionsList.length - 1 === index && permissionsList.length < 3 &&
                                (
                                    <>
                                    <button className={styles.action_button} onClick={handlePermissionAdd} key={index}>
                                        <svg className={styles.button_icon} fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-11a1 1 0 10-2 0v2H7a1 1 0 100 2h2v2a1 1 0 102 0v-2h2a1 1 0 100-2h-2V7z" clipRule="evenodd"></path></svg>
                                    </button>
                                    {/* <button className={styles.add_permission_button} onClick={handlePermissionRemove(index)}>
                                        <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 12H9m12 0a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                                    </button> */}
                                    </>
                                )}
                        </>
                        )
                    }
                    )}
                    <div>
                        <button 
                            className={styles.button}
                            onClick={() => {
                                handleInitializePermissionsSubmit()
                                }
                            }
                        >
                            <p>Initialize Permissions</p>
                        </button>
                    </div>
                </div>
            </div>
        </div>

    )
}