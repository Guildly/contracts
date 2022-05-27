import { useRef, useState, useEffect } from 'react'
import styles from '../styles/components/Header.module.css'
import Link from 'next/link'
import { useStarknet, InjectedConnector } from '@starknet-react/core';
import { useDisplayName } from "../hooks/starknet";

function Header({ highlighted }) {

    const { account, connect, disconnect } = useStarknet() 
    const address = useDisplayName(account)

    const networkRef = useRef<HTMLDivElement>(null)

    const [isNetworkDropdownSelected, setIsNetworkDropdownSelected] = useState(false)

    const chechIfNetworkCLickedOutside = (event: any) => {
        if(
            isNetworkDropdownSelected && 
            networkRef.current && 
            !networkRef.current.contains(event.target)
        ) {
            setIsNetworkDropdownSelected(false)
        }
    }

    useEffect(() => {
        document.addEventListener("click", chechIfNetworkCLickedOutside, true)
        return () => {
            document.removeEventListener("click", chechIfNetworkCLickedOutside, true)
        }
    }, [isNetworkDropdownSelected])

    const handleNetworkDropdown = () => {
        if (isNetworkDropdownSelected) {
            setIsNetworkDropdownSelected(false)
        }
        else {
            setIsNetworkDropdownSelected(true)
        }
    }

    return (
        <nav className={styles.header}>
            <div className={styles.links}>
                <div className={styles.icons}>
                    <Link href="/" passHref>
                        <img className={styles.logo} src="/logo.svg" alt="Guilds Logo" />
                    </Link>

                    <Link href="/home" passHref>
                        <div className={[styles.button, (highlighted == "home" ? styles.highlighted : styles.normal), styles.button_div].join(" ")}>
                            <svg className={styles.icon} fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path d="M10.707 2.293a1 1 0 00-1.414 0l-7 7a1 1 0 001.414 1.414L4 10.414V17a1 1 0 001 1h2a1 1 0 001-1v-2a1 1 0 011-1h2a1 1 0 011 1v2a1 1 0 001 1h2a1 1 0 001-1v-6.586l.293.293a1 1 0 001.414-1.414l-7-7z"></path></svg>
                            <p className={styles.button_text}>
                                Home
                            </p>
                        </div>
                    </Link>

                    <Link href="/create" passHref>
                        <div className={[styles.button, (highlighted == "create" ? styles.highlighted : styles.normal), styles.button_div].join(" ")}>
                            <svg className={styles.icon} fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-11a1 1 0 10-2 0v2H7a1 1 0 100 2h2v2a1 1 0 102 0v-2h2a1 1 0 100-2h-2V7z" clipRule="evenodd"></path></svg>
                            <p className={styles.button_text}>
                                Create
                            </p>
                        </div>
                    </Link>

                    <Link href="/manage" passHref>
                        <div className={[styles.button, (highlighted == "manage" ? styles.highlighted : styles.normal), styles.button_div].join(" ")}>
                        <svg className={styles.icon} fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4"></path></svg>                        
                            <p className={styles.button_text}>
                                Manage
                            </p>
                        </div>
                    </Link>

                    <Link href="/explore" passHref>
                        <div className={[styles.button, (highlighted == "explore" ? styles.highlighted : styles.normal), styles.button_div].join(" ")}>
                        <svg className={styles.icon} fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"></path></svg>                   
                            <p className={styles.button_text}>
                                Explore
                            </p>
                        </div>
                    </Link>

                    <a className={styles.link} href='https://www.notion.so/Game-Guilds-33c8008e033d4040b9438edf5225c580' target="_blank">
                        <div className={[styles.button, (highlighted == "docs" ? styles.highlighted : styles.normal), styles.button_div].join(" ")}>
                            <svg className={styles.icon} fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path d="M9 4.804A7.968 7.968 0 005.5 4c-1.255 0-2.443.29-3.5.804v10A7.969 7.969 0 015.5 14c1.669 0 3.218.51 4.5 1.385A7.962 7.962 0 0114.5 14c1.255 0 2.443.29 3.5.804v-10A7.968 7.968 0 0014.5 4c-1.255 0-2.443.29-3.5.804V12a1 1 0 11-2 0V4.804z"></path></svg>
                            <p className={styles.button_text}>
                                Docs
                            </p>
                        </div>
                    </a>
                </div>
            </div>
            <div className={styles.network_container} ref={networkRef}>
                {account ? (
                    <button 
                        className={
                            [
                                styles.network_button, 
                                styles.button, 
                                styles.highlighted, 
                                styles.button_div
                            ].join(" ")
                        }
                        onClick={() => handleNetworkDropdown()}
                    >
                        <p className={styles.network_button_text}>{address}</p>
                    </button>
                ):(
                    <button 
                        className={
                            [
                                styles.network_button, 
                                styles.button, 
                                styles.highlighted, 
                                styles.button_div
                            ].join(" ")
                        }
                        onClick={() => connect(new InjectedConnector())}
                    >
                        <p className={styles.network_button_text}>Connect Wallet</p>
                    </button>
                )}
            </div>
            {isNetworkDropdownSelected ? (
                <div className={styles.network_dropdown}>
                    <button className={
                            [
                                styles.network_button, 
                                styles.button, 
                                styles.highlighted, 
                                styles.button_div
                            ].join(" ")
                        }
                        onClick={() => disconnect(new InjectedConnector())}
                    >
                        <svg className={styles.network_button_icon} fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                        <p className={styles.network_button_text}>Disconnect</p>
                    </button>
                </div>
            ): undefined}
        </nav>
    );

}
export default Header;
