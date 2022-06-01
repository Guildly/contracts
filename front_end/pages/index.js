import styles from '../styles/Home.module.css'
import { useState, useMemo } from "react";
import { useStarknet, InjectedConnector } from '@starknet-react/core'
import Link from 'next/link'
import Showcase from '../components/showcase'
import WalletMenu from '../components/walletmenu'
import { useRouter } from 'next/router'

export default function Home() {

  const scroll = () => window.scrollTo({ top: window.innerWidth * window.devicePixelRatio, behavior: 'smooth' });
  const [connectMenuToggled, setConnectMenuToggled] = useState(false);
  const { account, connect, connectors } = useStarknet()
  const injected = useMemo(() => new InjectedConnector(), [])
  const router = useRouter()

  return (
    <div className={"background"}>
      {connectMenuToggled && !account ? <WalletMenu close={() => setConnectMenuToggled(false)} /> : null}
      <div className={styles.page}>
        <img className={styles.logo} src="/logo.svg" alt="Guilds logo" />

        <div className={styles.buttons}>

          <div className={styles.button}>
            <svg onClick={(async () => {
              if (connectors.length === 1) {
                const connector = connectors[0];
                try {
                  await connector.ready();
                  connect(connector)
                  router.push('/home');
                } catch (err) {
                  setConnectMenuToggled(true)
                }
              }
            })} className={styles.icon} fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-6-3a2 2 0 11-4 0 2 2 0 014 0zm-2 4a5 5 0 00-4.546 2.916A5.986 5.986 0 0010 16a5.986 5.986 0 004.546-2.084A5 5 0 0010 11z" clipRule="evenodd"></path></svg>

            <div className={[styles.icon_text, styles.icon_middle].join(" ")}>
              account
            </div>
          </div>

          <div className={styles.button}>
            <svg onClick={(async () => {
              if (connectors.length === 1) {
                const connector = connectors[0];
                try {
                  await connector.ready();
                  connect(connector)
                  router.push('/create');
                } catch (err) {
                  setConnectMenuToggled(true)
                }
              }
            })} className={styles.icon} fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-11a1 1 0 10-2 0v2H7a1 1 0 100 2h2v2a1 1 0 102 0v-2h2a1 1 0 100-2h-2V7z" clipRule="evenodd"></path></svg>
            <div className={[styles.icon_text, styles.icon_right].join(" ")}>
              create
            </div>
          </div>

          <div className={styles.button}>
            <svg onClick={(async () => {
              if (connectors.length === 1) {
                const connector = connectors[0];
                try {
                  await connector.ready();
                  connect(connector)
                  router.push('/manage');
                } catch (err) {
                  setConnectMenuToggled(true)
                }
              }
            })} className={styles.icon} fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
            <div className={[styles.icon_text, styles.icon_right].join(" ")}>
              manage
            </div>
          </div>

          <div className={styles.button}>
            <svg onClick={(async () => {
              if (connectors.length === 1) {
                const connector = connectors[0];
                try {
                  await connector.ready();
                  connect(connector)
                  router.push('/explore');
                } catch (err) {
                  setConnectMenuToggled(true)
                }
              }
            })} className={styles.icon} fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M8 16l2.879-2.879m0 0a3 3 0 104.243-4.242 3 3 0 00-4.243 4.242zM21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
            <div className={[styles.icon_text, styles.icon_right].join(" ")}>
              explore
            </div>
          </div>

        </div>
        <svg onClick={scroll} className={styles.scroll_icon} fill="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path fillRule="evenodd" d="M15.707 4.293a1 1 0 010 1.414l-5 5a1 1 0 01-1.414 0l-5-5a1 1 0 011.414-1.414L10 8.586l4.293-4.293a1 1 0 011.414 0zm0 6a1 1 0 010 1.414l-5 5a1 1 0 01-1.414 0l-5-5a1 1 0 111.414-1.414L10 14.586l4.293-4.293a1 1 0 011.414 0z" clipRule="evenodd"></path></svg>
      </div>

      <div className={styles.page}>
        <Showcase />
      </div>
    </div>
  )
}
