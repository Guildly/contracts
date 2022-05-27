import { number } from 'starknet';
import styles from '../styles/components/WalletMenu.module.css'
import Spinner from "./spinner";

interface JoinDialogProps {
    close: () => void;
    loading: boolean;
    value: number;
    setValue: (event: number) => void;
}

function JoinDialog(
    { 
        close,
        loading,
        value,
        setValue
    }: JoinDialogProps) {
    return (
        <div className={styles.menu}>
            {close ? 
            <button className={styles.menu_close} onClick={() => { close() }} >
                <svg alt="close icon" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12"></path></svg>
            </button>
                : null}
            <p className={styles.menu_title}>Joining</p>
            <p className={styles.menu_text}>
                Minting a guild certificate based on your whitelisted role.
            </p>
            {
                value === 1 ?
                    <Spinner color={"#a9d1ff"} className={styles.spinner_bottom} />
                    :
                    null
            }

            {
                value === 2 ?
                <div className={styles.box_footer}>
                    <a href={"https://goerli.voyager.online/tx/0x0"} target="_blank" rel="noreferrer" className={[styles.footer_element, styles.button_normal].join(" ")}>
                        <svg className={styles.button_icon} fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"></path></svg>
                        <p className={styles.button_text}>Track</p>
                    </a>
                </div>
                :
                null
            }
        </div>
    );

}
export default JoinDialog;
