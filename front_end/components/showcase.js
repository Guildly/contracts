import styles from '../styles/components/Showcase.module.css'

export default function Showcase() {
    return (
        <>
            <div className={[styles.card, styles.left].join(" ")}>
                <div>
                    <h1>What are Guilds?</h1>
                    <p>
                        Guilds are shared accounts between players. The account has multiple members with a permission system allowing controlled token usage.
                    </p>
                </div>
                <img className={styles.mask1} src="/illustrations/warrior1.webp" alt="A warrior" />
            </div>

            <div className={[styles.card, styles.rev_card, styles.right].join(" ")}>
                <div>
                    <h1>Who is it for?</h1>
                    <p>The guild is for anyone to create and use for any game. Mechanisms within it allow token owners to benefit from sharing, and members usage of tokens they don't hold.</p>
                </div>
                <img className={styles.mask2} src="/illustrations/warrior1.webp" alt="A warrior" />
            </div>

            <div className={[styles.card, styles.left].join(" ")}>
                <div>
                    <h1>Developer?</h1>
                    <p>
                        See our standard contracts and interfaces to allow your game to be compatible with guilds.
                    </p>
                </div>
                <img className={styles.mask3} src="/illustrations/warrior1.webp" alt="A warrior" />
            </div>
        </>
    );

}

