import styles from '../styles/components/Navbar.module.css'
import { useStarknet, InjectedConnector, useStarknetInvoke } from '@starknet-react/core'
import Link from 'next/link'

export const Navbar = () => {

    const { account, connect, disconnect } = useStarknet()


    return (
        <div className={styles.navbar}>
            <div className={styles.links}>
                <div className={styles.links_container}>
                    <Link href="/" passHref>
                        <p>Home</p>
                    </Link>
                    <Link href="/guilds" passHref>
                        <p>Guilds</p>
                    </Link>
                </div>
            </div>
            <div className={styles.wallet}>
                {account ? (
                    <>
                        <button className={styles.wallet_address_button}>
                            <p>{`${account?.slice(0, 5)}...${account?.slice(-4)}`}</p>
                        </button>
                        <button className={styles.wallet_disconnect_button}
                            onClick={() => disconnect(new InjectedConnector())}>
                            <p>Disconnect</p>
                        </button>
                    </>
                ) : (
                    <>
                        <button className={styles.wallet_connect_button}
                            onClick={() => connect(new InjectedConnector())}
                        >
                            <p>Connect</p>
                        </button>
                    </>
                )}
            </div>
        </div>

    )
}