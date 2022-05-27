import styles from '../styles/Account.module.css'

import { useStarknet } from '@starknet-react/core'
import { useDisplayName } from "../hooks/starknet";
import { useGuildCertificate } from '../hooks/guilds';
import { useStarknetCall } from '@starknet-react/core';
import GuildBox from '../components/guildbox';
import Header from '../components/header';
import Link from 'next/link';
import { Main } from '../features/Main';

export default function Account() {

  const { account } = useStarknet();
  const name = useDisplayName(account);
  const { contract: GuildCertificate } = useGuildCertificate();
  // const { data } = useStarknetCall({ contract: contract, method: 'get_user_guilds', args: [account] });
  const { supportedGuilds } = Main()

  return (
    <div className="background">
      <Header highlighted={"home"} />
      <div className="content">
        <div className={styles.box}>
          <div className={styles.header}>
            <img className={styles.profilepicture} src="/illustrations/warrior1.webp" alt="A warrior" />
            <div className={styles.info}>
              <h1 className={styles.title}>Gm {name}</h1>
              <p className={styles.data_text}>
                You are part of 2 guilds and have played for a total of <span className={styles.data_number}>{Math.floor(Math.random() * 100)}</span> hours.
              </p>
              <Link className={styles.data_text} href="test-token" passHref>
                <button className={styles.button}>
                  <p className={styles.button_text}>Mint Test Token</p>
                </button>
              </Link>
              {/* <div className={styles.info_footer}>
                <div className={styles.icon_container}>
                  <svg className={styles.icon} fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clipRule="evenodd"></path></svg>
                  <div className={styles.icon_text}>notifs</div>
                </div>
                <div className={styles.icon_container}>
                  <svg className={styles.icon} fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path fillRule="evenodd" d="M2 5a2 2 0 012-2h8a2 2 0 012 2v10a2 2 0 002 2H4a2 2 0 01-2-2V5zm3 1h6v4H5V6zm6 6H5v2h6v-2z" clipRule="evenodd"></path><path d="M15 7h1a2 2 0 012 2v5.5a1.5 1.5 0 01-3 0V7z"></path></svg>
                  <div className={styles.icon_text}>news</div>
                </div>
                <div className={styles.icon_container}>
                  <svg className={styles.icon} fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path fillRule="evenodd" d="M4 4a2 2 0 00-2 2v4a2 2 0 002 2V6h10a2 2 0 00-2-2H4zm2 6a2 2 0 012-2h8a2 2 0 012 2v4a2 2 0 01-2 2H8a2 2 0 01-2-2v-4zm6 4a2 2 0 100-4 2 2 0 000 4z" clipRule="evenodd"></path></svg>
                  <div className={styles.icon_text}>dividends</div>
                </div>
              </div> */}
            </div>
          </div>
        </div>

        <div className={styles.guilds}>
          {/* {data ? data.guilds.map((guild) => <GuildBox key={guild} guild={guild} />) : undefined} */}
          {supportedGuilds ? supportedGuilds.map((guild, index) => 
            <GuildBox guild={guild} key={index} />) 
            : undefined
          }
        </div>
      </div>
    </div>
  )
}
