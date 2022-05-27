import { useState } from 'react'
import styles from '../styles/TestGame.module.css'
import Header from '../components/header';
import ShortTextInput from "../components/input";
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


export default function TestGame() {

    const guild = "0x0544ca787ac6f35fe1196badf06c4b247ea04ad3da10035d021ef05af86708c0"

    const gameContractAddress = "0"

    const { contract: guildContract } = useGuildsContract(guild);

    const { contract: gameContract } = useTestGameContract();

    const { data: getValueResult } = useStarknetCall(
        {
            contract: gameContract, 
            method: 'get_value', 
            args: []
        }
    );

    const { data: guildExecuteData, loading: guildExecuteLoading, invoke: guildExecuteInvoke } = useStarknetInvoke(
        { 
            contract: guildContract, 
            method: 'execute_transaction' 
        }
    );

    const [value, setValue] = useState("")

    const tokenId = {
        low: toBN(1),
        high: toBN(0)
    }

    const setValueExecuteArgs = [
        gameContractAddress, 
        getSelectorFromName("set_value"),
        [toBN(value),tokenId]
    ]

    // console.log(args)

    return(
        <div className="background">
            <Header />
            <div className="content">
                <div className={styles.box}>
                    <h1 className={styles.title}>Test Game</h1>
                    <h2 className={styles.subtitle}>Action</h2>
                    <div className={styles.action}>
                        <p className={styles.description}>
                            Test setting a value with an NFT gated function. Uses the Test
                            NFT.
                        </p>
                        <div>
                            <ShortTextInput content={value} setContent={setValue} label="Enter value"/>
                            <button 
                                className={styles.button}
                                onClick={() => 
                                    guildExecuteInvoke({
                                        args: setValueExecuteArgs,
                                        metadata: { 
                                            method: 'set_value_with_nft', 
                                            message: 'set value with NFT' 
                                        }
                                    })
                                }
                            >
                                <p className={styles.button_text}>Set Game Value</p>
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    )
}