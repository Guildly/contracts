import { useRouter } from 'next/router';
import { useGuildsContract } from '../../hooks/guilds';
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

  const guildName = "Titans of the Dark Circle";
  const token = "0x043cc9735efbb2b54ea79009dca04555f9e4377344bbd75a1c98f00378994037";
  const tokenId = {
    low: toBN(1),
    high: toBN(0)
  }

  const guildItems = ["Token"]

  console.log(account, guild? guild.address : undefined, token, tokenId)

  return (
    <div className="background">
      <Header highlighted={"home"} />

      <div className="content">

        <h1 className={styles.title}>{guildName}</h1>

        <div className={styles.main}>

          <div className={styles.big_card}>
            <h2 className={styles.subtitle}>Leaderboard</h2>

            
          </div>
          <div className={styles.right}>
            <div className={styles.card}>
              <h2 className={styles.subtitlebis}>Games</h2>
              <p className={styles.descline}>Age Of Eykar</p>
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
          {guildItems ? (
            guildItems.map((item, index) => 
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
                    <td>Legendary Sword</td>
                    <td>Eykar</td>
                    <td>1</td>
                    <td>
                      <button 
                        className={styles.button_add}
                        onClick={() => 
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
                        }
                      >
                        <svg className={styles.icon} fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 12H9m12 0a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                      </button>
                    </td>
                  </tr>
                </tbody>
              </table>
            )
          ):(
            <p className={styles.subtitlebis}>No items in guild</p>
          )}
        </div>
        
        <h2 className={styles.subtitle}>Add Items</h2>
        
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
                <td>Legendary Sword</td>
                <td>Eykar</td>
                <td>1</td>
                <td>
                  <button 
                    className={styles.button_add}
                    onClick={() => 
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
                    }
                  >
                    <svg className={styles.icon} fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-11a1 1 0 10-2 0v2H7a1 1 0 100 2h2v2a1 1 0 102 0v-2h2a1 1 0 100-2h-2V7z" clipRule="evenodd"></path></svg>
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  )
}
