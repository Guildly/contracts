import { useState, useEffect } from "react";
import { useRouter } from 'next/router';
import { useGuildsContract } from '../../hooks/guilds';
import { useTestNFTContract } from '../../hooks/testNFT';
import { 
  useStarknet, 
  useStarknetCall, 
  useStarknetInvoke,
  useStarknetTransactionManager 
} from '@starknet-react/core';
import styles from '../../styles/Panel.module.css'
import Header from '../../components/header';
import { toBN } from 'starknet/dist/utils/number';
import { Main } from '../../features/Main';
import Link from 'next/link';
import TransactionDialog from '../../components/transactionDialog';
import deploymentsConfig from '../../deployments-config.json'

export const getGuild = (pid) => {
  const { supportedGuilds } = Main()
  return supportedGuilds.find(
    guild => guild.slug === pid
  )
}

export default function Panel() {
  
  const router = useRouter()
  const { pid } = router.query

  const guild = getGuild(pid)

  const { account } = useStarknet();

  const { contract: guildContract } = useGuildsContract(guild? guild.address : 0);
  const { contract: testNFTContract } = useTestNFTContract();

  // const { data: guildItems } = useStarknetCall({ contract: guildContract, method: 'get_items', args: [] });

  const { data: depositData, loading: depositLoading, invoke: depositInvoke } = useStarknetInvoke(
    { 
        contract: guildContract,
        method: 'deposit_ERC721' 
    }
  );

  const { data: withdrawData, loading: withdrawLoading, invoke: withdrawInvoke } = useStarknetInvoke(
    { 
        contract: guildContract,
        method: 'withdraw_ERC721' 
    }
  );

  const token = deploymentsConfig["networks"]["goerli"]["test_nft"];
  const tokenId = {
    low: toBN(1),
    high: toBN(0)
  }

  const [depositDialogToggled, setDepositDialogToggled] = useState(false);

  const [withdrawDialogToggled, setWithdrawDialogToggled] = useState(false);

  const [depositToken, setDepositToken] = useState(false);
  const [withdrawToken, setWithdrawToken] = useState(false);

  const { data: ownedItemsCount } = useStarknetCall(
    { 
      contract: testNFTContract, 
      method: 'token_id_count', 
      args: [] 
    }
  );

  const ownedItems = []

  if (ownedItemsCount) {
    for (var i=0; i<ownedItemsCount[0].low; i++) {
      ownedItems[i] = i
    }
  }

  const { transactions } = useStarknetTransactionManager()

  useEffect(() => {
    for (const transaction of transactions) {
      if (transaction.transactionHash === depositData) {
        if (transaction.status === 'ACCEPTED_ON_L2'
          || transaction.status === 'ACCEPTED_ON_L1')
          setDepositToken(true);
      }
      if (transaction.transactionHash === withdrawData) {
        if (transaction.status === 'ACCEPTED_ON_L2'
          || transaction.status === 'ACCEPTED_ON_L1')
          setWithdrawToken(true);
      }
    }
  }, [depositData, withdrawData, transactions])

  console.log(ownedItemsCount)
  console.log(ownedItems)

  return (
    <div className="background">
      <Header highlighted={"home"} />

      <div className="content">

        {depositDialogToggled ? 
          <TransactionDialog
              title={"Deposit Item"}
              description={"Deposit item into " +guild.name}
              close={() => setDepositDialogToggled(false)}
              loading={depositLoading}
              value={depositToken}
              setValue={setDepositToken}
          /> : null}

        {withdrawDialogToggled ? 
          <TransactionDialog
              title={"Withdraw Item"}
              description={"Withdraw item from "+guild.name}
              close={() => setWithdrawDialogToggled(false)}
              loading={withdrawLoading}
              value={withdrawToken}
              setValue={setWithdrawToken}
          /> : null}

        <h1 className={styles.title}>{guild ? guild.name : "..."}</h1>

        <div className={styles.main}>

          <div className={styles.big_card}>
            <h2 className={styles.subtitle}>Leaderboard</h2>

            
          </div>
          <div className={styles.right}>
            <div className={styles.card}>
              <h2 className={styles.subtitlebis}>Games</h2>
              <div className={styles.game_row}>
                <p className={styles.descline}>Age Of Eykar</p>
                <Link href="/test-game">
                    <div className={styles.button}>
                      <p className={styles.play_button_text}>Play</p>
                    </div>
                </Link>
              </div>
              <p className={styles.descline}>Battle In Redacted</p>
            </div>
            <div className={styles.card}>
              <h2 className={styles.subtitlebis}>Permissions</h2>
              <p className={styles.descline}>Eykar Battle</p>
              <p className={styles.descline}>Side Quests</p>
            </div>

          </div>
        </div>

        <h2 className={styles.subtitle}>Guild Items</h2>

        <div className={styles.box}>
              <table className={styles.table}>
                <thead>
                  <tr>
                      <th>Name</th>
                      <th>Type</th>
                      <th>Amount</th>
                      <th></th>
                  </tr>
                </thead>
                <tbody>
                  <tr>
                    <td>Castle Key</td>
                      <td>Eykar</td>
                      <td>1</td>
                      <td>{/* <button 
                        className={styles.button_add}
                        onClick={() => {
                          withdrawInvoke({
                              args: [
                                  token,
                                  tokenId
                              ],
                              metadata: { 
                                  method: 'withdraw_ERC721', 
                                  message: 'withdraw ERC721 from guild' 
                              }
                          })
                          setWithdrawDialogToggled(true)
                          }
                        }
                      >
                        <svg className={styles.icon} fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 12H9m12 0a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                      </button> */}
                    </td>
                  </tr>
                </tbody>
              </table>
            {/* <p className={styles.subtitlebis}>No items in guild</p> */}
        </div>
        
        <h2 className={styles.subtitle}>Add Items</h2>
        
        <div className={styles.box}>
          {ownedItems.length > 0 ?
            (
              <table className={styles.table}>
                <thead>
                  <tr>
                      <th>Name</th>
                      <th>Type</th>
                      <th>Amount</th>
                      <th></th>
                  </tr>
                </thead>
                <tbody>
                    {ownedItems.map((item, index) => 
                    <tr>
                      <td>Legendary Sword</td>
                      <td>Eykar</td>
                      <td>1</td>
                      <td>
                        <button 
                          className={styles.button_add}
                          onClick={() => {
                            depositInvoke({
                                args: [
                                    token,
                                    tokenId
                                ],
                                metadata: { 
                                    method: 'deposit_ERC721', 
                                    message: 'deposit ERC721 to guild' 
                                }
                            })
                            setDepositDialogToggled(true)
                            }
                          }
                        >
                          <svg className={styles.icon} fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-11a1 1 0 10-2 0v2H7a1 1 0 100 2h2v2a1 1 0 102 0v-2h2a1 1 0 100-2h-2V7z" clipRule="evenodd"></path></svg>
                        </button>
                      </td>
                    </tr>
                    )}
                </tbody>
              </table>
            )
            :
            (
              <p className={styles.table_text}>No items owned</p>
            )
          }
        </div>
      </div>
    </div>
  )
}
