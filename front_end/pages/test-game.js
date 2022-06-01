import { useState, useEffect } from 'react'
import styles from '../styles/TestGame.module.css'
import Header from '../components/header';
import { ShortTextInput } from "../components/input";
import { 
    useStarknet, 
    useStarknetCall, 
    useStarknetInvoke,
    useStarknetTransactionManager 
} from '@starknet-react/core'
import { useGuildsContract } from '../hooks/guilds';
import { useTestGameContract } from '../hooks/testGame';
import { toBN } from 'starknet/dist/utils/number';
import { getSelectorFromName } from "starknet/dist/utils/hash";
import deploymentsConfig from '../deployments-config.json'
import TransactionDialog from '../components/transactionDialog';
import { stringToFelt, feltToString } from '../utils/felt';
import { 
    fromCallsToExecuteCalldata,
    transformCallsToMulticallArrays
} from 'starknet/utils/transaction'

export default function TestGame() {

    const { account } = useStarknet()

    const guild = deploymentsConfig["networks"]["goerli"]["test_guild_1"]

    const game = deploymentsConfig["networks"]["goerli"]["test_game_contract"]

    const { contract: guildContract } = useGuildsContract(guild);

    const { contract: gameContract } = useTestGameContract();

    const { data: getValueResult } = useStarknetCall(
        {
            contract: gameContract, 
            method: 'get_character_name', 
            args: [account]
        }
    );

    const getCharacterNameValue = getValueResult ? feltToString(getValueResult[0]) : 0

    // console.log(getValueResult ? getValueResult[0].toString() : 0)

    const { data: openDoorResult } = useStarknetCall(
        {
            contract: gameContract, 
            method: 'get_door', 
            args: [account]
        }
    );

    const openDoorValue = openDoorResult ? openDoorResult[0].toString() : 0

    const { data: nonceResult } = useStarknetCall(
        {
            contract: guildContract,
            method: 'get_nonce',
            args: []
        }
    )

    const { data: guildExecuteData, loading: guildExecuteLoading, invoke: guildExecuteInvoke } = useStarknetInvoke(
        { 
            contract: guildContract, 
            method: 'execute_transactions' 
        }
    );

    const [value, setValue] = useState("")

    // const setCharacterNameCalls = [(
    //     game,
    //     "set_character_name",
    //     [toBN(stringToFelt(value)),toBN(account)]
    // )]

    const setCharacterNameCalls = [
        {
            contractAddress: game,
            entrypoint: "set_character_name",
            calldata: [toBN(stringToFelt(value)),toBN(account)]
        }
    ]
    // console.log(setCharacterNameCalls2)

    const openDoorCalls = [
        {
            contractAddress: game,
            entrypoint: "open_door",
            calldata: [toBN(account), toBN(1), toBN(0)]
        }
    ]

    const handleGuildExecuteSubmit = (calls, metadata) => {
        const {callArray, calldata } = transformCallsToMulticallArrays(calls)
        guildExecuteInvoke({
            args: [
                callArray, calldata, nonceResult[0].toString()
            ],
            metadata: metadata
        })

    }

    const { transactions } = useStarknetTransactionManager()

    useEffect(() => {
        for (const transaction of transactions) {
          if (transaction.transactionHash === guildExecuteData) {
            if (transaction.status === 'ACCEPTED_ON_L2'
              || transaction.status === 'ACCEPTED_ON_L1')
              setCharacterName(true);
          }
        }
    }, [guildExecuteData, transactions])

    const [characterName, setCharacterName] = useState(false);

    const [characterNameDialogToggled, setCharacterNameDialogToggled] = useState(false);

    const [openDoor, setOpenDoor] = useState(false);

    const [openDoorDialogToggled, setOpenDoorDialogToggled] = useState(false);

    return(
        <div className="background">
            <Header />
            <div className="content">

                {
                    characterNameDialogToggled ?
                    <TransactionDialog
                        title={"Set Character Name"}
                        description={"Setting name of your character."}
                        close={() => setCharacterNameDialogToggled(false)}
                        loading={guildExecuteLoading}
                        value={characterName}
                        setValue={setCharacterName}
                    /> : null
                }

                {
                    openDoorDialogToggled ?
                    <TransactionDialog
                        title={"Open Door"}
                        description={"Opening the castle door."}
                        close={() => setOpenDoorDialogToggled(false)}
                        loading={guildExecuteLoading}
                        value={openDoor}
                        setValue={setOpenDoor}
                    /> : null
                }
                <div className={styles.box}>
                    <h1 className={styles.title}>Test Game</h1>
                    <h2 className={styles.subtitle}>Character Name</h2>
                    <div className={styles.action}>
                        <p className={styles.description}>
                            Set the name of your character.
                        </p>
                        <div>
                            <ShortTextInput content={value} setContent={setValue} label="Enter Name"/>
                            <button 
                                className={styles.button}
                                onClick={() => {
                                    handleGuildExecuteSubmit(
                                        setCharacterNameCalls,
                                        {
                                            method: 'set character name',
                                            message: 'set accounts character name'
                                        })
                                    setCharacterNameDialogToggled(true)
                                    }
                                }
                            >
                                <p className={styles.button_text}>Set Character Name</p>
                            </button>
                        </div>
                    </div>
                    <div>
                        {
                            getValueResult ? 
                            <p className={styles.description}>Name is {getCharacterNameValue}</p>
                            :
                            <p className={styles.description}>No character name set</p>
                        }
                    </div>
                    <h2 className={styles.subtitle}>Unlock Door</h2>
                    <div className={styles.action}>
                        {
                            openDoorValue == '1' ? 
                            <p className={styles.description}>
                                You open the door and see a drunk wizard staring back at you.
                            </p>
                            :
                            <p className={styles.description}>
                                You are staring at a shut wooden door.
                            </p>
                        }
                        <button 
                            className={styles.button}
                            onClick={() => {
                                handleGuildExecuteSubmit(
                                    openDoorCalls,
                                    {
                                        method: 'open door',
                                        message: 'open door for account'
                                    })
                                setOpenDoorDialogToggled(true)
                                }
                            }
                        >
                            <p className={styles.button_text}>Unlock Door</p>
                        </button>
                    </div>
                </div>
            </div>
        </div>
    )
}