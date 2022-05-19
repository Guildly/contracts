import styles from '../styles/components/Showcase.module.css'

export default function Showcase() {
    return (
        <>
            <div className={[styles.card, styles.left].join(" ")}>
                <div>
                    <h1>What are Guilds?</h1>
                    <p>
                        Aut perferendis ea et dolores vero id. Cumque in doloribus laboriosam aut itaque. Quos ut natus at. Et placeat non neque vel sunt quas illum voluptas. Nostrum aut aut a.
                    </p>
                </div>
                <img className={styles.mask1} src="/illustrations/warrior1.webp" alt="A warrior" />
            </div>

            <div className={[styles.card, styles.rev_card, styles.right].join(" ")}>
                <div>
                    <h1>Who is it for?</h1>
                    <p>Vitae atque hic eos voluptas in eaque. Sapiente dolorem quasi asperiores. Aliquam eveniet quidem at commodi aut.</p>
                </div>
                <img className={styles.mask2} src="/illustrations/warrior1.webp" alt="A warrior" />
            </div>

            <div className={[styles.card, styles.left].join(" ")}>
                <div>
                    <h1>Developer?</h1>
                    <p>
                        Odio repudiandae sed occaecati aliquam corporis reiciendis. Reprehenderit explicabo voluptates est. Officiis est labore et aut illo facere.</p>
                </div>
                <img className={styles.mask3} src="/illustrations/warrior1.webp" alt="A warrior" />
            </div>
        </>
    );

}

