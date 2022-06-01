import { number } from 'starknet';
import styles from '../styles/components/TransactionDialog.module.css'
import Spinner from "./spinner";

interface TransactionDialogProps {
    title: string;
    description: string;
    close: () => void;
    loading: boolean;
    value: number;
    setValue: (event: number) => void;
}

function TransactionDialog(
    { 
        title,
        description,
        close,
        loading,
        value,
        setValue
    }: TransactionDialogProps) {
    return (
        <div className={styles.dialog}>
            {close ? 
            <button className={styles.dialog_close} onClick={() => { close() }} >
                <svg viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M6 18L18 6M6 6l12 12"></path></svg>
            </button>
                : null}
            <p className={styles.dialog_title}>{title}</p>
            <p className={styles.dialog_text}>
                {description}
            </p>
            {
                !value ?
                    <Spinner color={"#a9d1ff"} className={styles.spinner_bottom} />
                    :
                    null
            }

            {
                value ?
                <div className={styles.box_footer}>
                    <a href={"https://goerli.voyager.online/tx/0x0"} target="_blank" rel="noreferrer" className={[styles.footer_element, styles.button].join(" ")}>
                        <svg className={styles.button_icon} fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"></path></svg>
                        <p className={styles.button_text}>Transaction</p>
                    </a>
                </div>
                :
                null
            }
        </div>
    );

}
export default TransactionDialog;
