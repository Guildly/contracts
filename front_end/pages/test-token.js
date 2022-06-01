import Header from '../components/header';
import styles from '../styles/Explore.module.css'
import { useState, useRef, useMemo, useEffect } from "react";
import ShortTextInput from "../components/input";
import Spinner from "../components/spinner";
import { 
    useStarknet, 
    useStarknetCall, 
    useStarknetInvoke,
    useStarknetTransactionManager 
} from '@starknet-react/core'
import { useTestNFTContract } from '../hooks/testNFT';
import { toBN } from 'starknet/dist/utils/number'
import TransactionDialog from '../components/transactionDialog'


export default function TestToken() {

    const { account } = useStarknet();
    const [ minted, setMinted ] = useState(false)
    const { contract: testNFTContract } = useTestNFTContract();
    const { data: tokenIdCountResult } = useStarknetCall({contract: testNFTContract, method: 'token_id_count', args: []});
    const { 
        data: tokenMintData, 
        loading: tokenMintLoading, 
        invoke: tokenMintInvoke 
    } = useStarknetInvoke(
        { 
            contract: testNFTContract, 
            method: 'mint' 
        });
    const { transactions } = useStarknetTransactionManager()

    useEffect(() => {
        for (const transaction of transactions)
          if (transaction.transactionHash === tokenMintData) {
            if (transaction.status === 'ACCEPTED_ON_L2'
              || transaction.status === 'ACCEPTED_ON_L1')
              setMinted(true);
          }
      }, [tokenMintData, transactions])

    const tokenIdValue = useMemo(() => {
        if (tokenIdCountResult && tokenIdCountResult.length > 0) {
          const value = parseFloat(toBN(tokenIdCountResult[0].low))
          const newValue = value + 1
          const parsedValue = {
              low: toBN(newValue),
              high: toBN(0)
            }
          return parsedValue
        }
    }, [tokenIdCountResult])

    const [mintDialogToggled, setMintDialogToggled] = useState(false);

    return(
        <div className="background">
            <Header />
            <div className="content">

                {
                    mintDialogToggled ?
                        <TransactionDialog
                            title={"Minting Token"}
                            description={"Minting a test ERC721 token."}
                            close={() => setMintDialogToggled(false)}
                            loading={tokenMintLoading}
                            value={minted}
                            setValue={setMinted}
                        /> : null
                }

                <div className={styles.box}>
                    <div className={styles.header}>
                        <h1 className={styles.title}>Mint Test Token</h1>
                    </div>
                    {
                        !tokenMintData && !tokenMintLoading ?
                        <div 
                            onClick={() => {
                                tokenMintInvoke({
                                    args: [account, tokenIdValue],
                                    metadata: { 
                                        method: 'mint', 
                                        message: 'mint a token' 
                                    }
                                })
                                setMintDialogToggled(true)
                                }
                            }
                            className={styles.button_normal}
                        >
                            <svg className={styles.button_icon} fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z"></path></svg>
                            <p className={styles.button_text}>Mint Token</p>
                        </div>
                        : null
                    }

                    {/* {
                        tokenMintLoading || (!minted && tokenMintData) ?
                        <Spinner color={"#a9d1ff"} className={styles.spinner_bottom} />
                        : null
                    } */}

                    {
                        minted ? <><h2 className={styles.subtitle}>Test Token Minted</h2></>
                        : undefined
                    }
                </div>
            </div>
        </div>
    )
}