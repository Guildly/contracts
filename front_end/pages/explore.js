import Header from '../components/header';
import styles from '../styles/Explore.module.css'
import { useState, useRef } from "react";
import ShortTextInput from "../components/input";
import Spinner from "../components/spinner";
import Link from 'next/link'
import { useStarknet } from '@starknet-react/core'

export default function Manage() {

    const { account } = useStarknet();
    // const { data } = useGuildsManaged(account);

    return(
        <div className="background">
            <Header highlighted={"explore"} />
            <div className={styles.box}>
                <div className={styles.header}>
                    <h1 className={styles.title}>Explore</h1>
                </div>
            </div>
        </div>
    )
}