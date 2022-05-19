import { useRouter } from 'next/router'
import { useGuildsContract } from '../../hooks/guilds';
import { useEffect, useState } from "react";
import styles from '../../styles/Create.module.css'
import Header from '../../components/header';
import { useDisplayName } from "../../hooks/starknet";
import { useStarknetInvoke } from '@starknet-react/core'
import { useStarknetTransactionManager } from '@starknet-react/core'
import { stringToFelt } from '../../utils/felt';
import Spinner from "../../components/spinner";

export default function Mint() {
  const router = useRouter()
  const [minted, setMinted] = useState(false)
  const { pid } = router.query
  const { contract } = useGuildsContract("" + pid);
  const { data, loading, invoke } = useStarknetInvoke({ contract: contract, method: 'mint' })
  const { transactions } = useStarknetTransactionManager()
  const name = useDisplayName(pid);

  useEffect(() => {
    for (const transaction of transactions)
      if (transaction.transactionHash === data) {
        if (transaction.status === 'ACCEPTED_ON_L2'
          || transaction.status === 'ACCEPTED_ON_L1')
          setMinted(true);
      }
  }, [data])

  return (
    <div className="background">
      <Header highlighted={"create"} />

      <div className={styles.box}>

        {
          !data && !loading
            ? <><h1 className={styles.title}>Guild name: {name}</h1>
              <div className={styles.box_footer}>


                <div onClick={() => {
                  invoke({ args: [["0x0"], [stringToFelt("Legendary Diplomat")]] })
                }} className={[styles.footer_element, styles.button_normal].join(" ")}>
                  <svg className={styles.button_icon} fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z"></path></svg>
                  <p className={styles.button_text}>Mint a share</p>
                </div>

              </div></>
            : null
        }

        {loading || (!minted && data)
          ? <><h1 className={styles.title}>Minting {name}</h1>
            <div className={styles.box_footer}>
              <Spinner color={"#a9d1ff"} className={styles.spinner_bottom} />
            </div></>
          : null
        }

        {
          minted ? <><h1 className={styles.title}>{name} share minted</h1></>
            : undefined
        }

      </div>
    </div>
  )
}
