import styles from '../../styles/Profile.module.css';
import Header from '../../components/header';
import { useRouter } from 'next/router';
import { Main } from '../../features/Main';

export const getGuild = (pid) => {
    const { supportedGuilds } = Main()
    return supportedGuilds.find(
      guild => guild.slug === pid
    )
}

export default function Profile() {

    const router = useRouter()
    const { pid } = router.query

    const guild = getGuild(pid)

    return(
        <div className="background">
            <Header />
            <div className="content">
                <div className={styles.box}>
                    <h1 className={styles.title}>{guild? guild.name : "..."}</h1>

                    <img className={styles.profilepicture} src="/illustrations/warrior1.webp" alt="A warrior" />

                    <div className={styles.description}>
                        <h2 className={styles.subtitle}>Description</h2>
                        <p>
                            Titans Of The Dark Circle is a guild on Eykar that allows the sharing of
                            resources between players. Members are allowed to battle, set up plots
                            where amounts of resouces allow you to do so.
                        </p>
                    </div>

                    <div className={styles.actions}>
                        <button className={styles.button}>
                            <p className={styles.button_text}>Request To Join</p>
                        </button>
                    </div>
                </div>
            </div>
        </div>
    )
}