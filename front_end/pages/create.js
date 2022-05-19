import Header from '../components/header';
import styles from '../styles/Create.module.css'
import { useState, useRef } from "react";
import ShortTextInput from "../components/input";
import Spinner from "../components/spinner";
import Link from 'next/link'
import { useStarknet } from '@starknet-react/core'

export default function Create() {

  const { account } = useStarknet();
  const [name, setName] = useState("");
  const [mint, setMint] = useState(0);
  const resp = useRef(null);

  return (
    <div className="background">
      <Header highlighted={"create"} />

      <div className={styles.box}>

        {
          mint === 0 ?
            <><h1 className={styles.title}>Create a Guild</h1>
              <ShortTextInput content={name} setContent={setName} />
              <div className={styles.box_footer}>
                {name ? <button onClick={() => {
                  // (async () => {
                  //   // const result = await (await fetch("/api/" + account + "/" + name, { method: 'GET' })).json();
                  //   // console.log(result)
                  //   // resp.current = result;
                  //   resp.current.transaction_hash = "0x0"
                  //   setMint(2)
                  // })();
                  setMint(2)
                }} className={[styles.footer_element, styles.button].join(" ")}>
                  <svg className={styles.button_icon} fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M12 9v3m0 0v3m0-3h3m-3 0H9m12 0a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>
                  <p className={styles.button_text}>Create</p>
                </button> : null}
              </div>
            </>
            : null
        }

        {
          mint === 1 ?
            <><h1 className={styles.title}>Generating contract</h1>
              <p className={styles.text}>
                Contract will soon be sent to StarkNet
                <Spinner color={"#a9d1ff"} className={styles.loading_icon} />
              </p>
            </>
            : null
        }

        {
          mint === 2 ?
            <><h1 className={styles.title}>Guild Contract Created</h1>

              <div className={styles.box_footer}>

                <a href={"https://goerli.voyager.online/tx/0x0"} target="_blank" rel="noreferrer" className={[styles.footer_element, styles.button_normal].join(" ")}>
                  <svg className={styles.button_icon} fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"></path></svg>
                  <p className={styles.button_text}>Track</p>
                </a>

                {/* <Link href={"/mint/" + resp.current.address} passHref>
                  <div className={[styles.footer_element, styles.button_normal].join(" ")}>
                    <svg className={styles.button_icon} fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 15l-2 5L9 9l11 4-5 2zm0 0l5 5M7.188 2.239l.777 2.897M5.136 7.965l-2.898-.777M13.95 4.05l-2.122 2.122m-5.657 5.656l-2.12 2.122"></path></svg>
                    <p className={styles.button_text}>Join</p>
                  </div>
                </Link> */}
              </div>

            </>
            : null
        }

      </div>
    </div>
  )
}
