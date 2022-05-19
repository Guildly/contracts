import { useRouter } from 'next/router';
import { useGuildsContract } from '../../hooks/guilds';
import styles from '../../styles/Panel.module.css'
import Header from '../../components/header';

export default function Panel() {
  const router = useRouter()
  const { contract } = useGuildsContract(router.query);

  const guildContract = "0x000a7a9203bff78bfb24f0753c184a33d4cad95b1f4f510b36b00993815704";
  const guildName = "Titans of the Dark Circle";
  const title = "Legendary Diplomat";
  const shares = 7;
  const totalShares = 100;
  const members = 47;
  const fundsValue = 1500;
  const extensions = 4;

  return (
    <div className="background">
      <Header highlighted={"home"} />

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
      
      <h2 className={styles.subtitle}>Add Items</h2>
      
      <div className={styles.box}>
      <table>
          <thead>
            <tr className={styles.table_header}>
                <th className={styles.table_first_header_item}>Name</th>
                <th>Type</th>
                <th>Amount</th>
                <th></th>
            </tr>
          </thead>
          <tbody>
            <tr className={styles.table_body}>
              <td className={styles.table_first_body_item}>Legendary Sword</td>
              <td>Eykar</td>
              <td>1</td>
              <td>
                <button className={styles.button_add}>
                  <svg className={styles.icon} fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-11a1 1 0 10-2 0v2H7a1 1 0 100 2h2v2a1 1 0 102 0v-2h2a1 1 0 100-2h-2V7z" clipRule="evenodd"></path></svg>
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

    </div>
  )
}
