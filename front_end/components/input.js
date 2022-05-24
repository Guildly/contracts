import styles from '../styles/components/TextInput.module.css'

function ShortTextInput({ content, setContent, label, icon }) {

    return (
        <div className={styles.group}>
            <input className={styles.input} type="text" required value={content} onChange={event => {
                if (event.target.value.length < 32)
                    setContent(event.target.value)
            }} />
            <span className={styles.highlight}></span>
            <span className={styles.bar}></span>
            {label || icon? 
                <label className={styles.label}>
                    <div className={styles.icon}>  
                        {icon}
                    </div>
                    {label} 
                </label>
                : null
            }
        </div>
    );
}
export default ShortTextInput;
