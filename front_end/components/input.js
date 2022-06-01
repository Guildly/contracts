import styles from '../styles/components/TextInput.module.css'

export function ShortTextInput({ content, setContent, label, icon }) {

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


export function LongTextInput({ content, setContent, label, icon }) {

    return (
        <div className={styles.group}>
            <input className={styles.input} type="text" required value={content} onChange={event => {
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

export function MultipleRowInput({ value, onChange, name, label, icon, errors }) {

    return (
        <div className={styles.group}>
            <input className={styles.input} type="text" required value={value} onChange={onChange} name={name} />
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
            {
                errors ? <p className={styles.error}>{errors.message}</p> : null
            }
        </div>
    );
}
