import { useState } from "react";
import styles from '../../styles/Profile.module.css';
import Header from '../../components/header';
import { useRouter } from 'next/router';
import { Main } from '../../features/Main';
import { 
    useStarknet,
    useStarknetCall,
    useStarknetInvoke
} from '@starknet-react/core'
import { useGuildsContract, useShareCertificate } from '../../hooks/guilds';
import JoinDialog from '../../components/joinDialog'

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

    const { contract: guildContract } = useGuildsContract(guild? guild.address: 0);

    const { 
        data: joinData, 
        loading: joinLoading, 
        invoke: joinInvoke 
    } = useStarknetInvoke(
        { 
            contract: guildContract,
            method: 'join' 
        }
    );
    
    const {data: whitelistedData} = useStarknetCall({contract: guildContract, method: "get_whitelisted_role", args: []})

    console.log(whitelistedData)

    const joinButtonDisabled = whitelistedData === 0 ? true : false

    const [joinDialogToggled, setJoinDialogToggled] = useState(false);

    const [mintCertificate, setMintCertificate] = useState(0)

    return(
        <div className="background">
            <Header />
            <div className="content">
                {joinDialogToggled ? 
                <JoinDialog 
                    close={() => setJoinDialogToggled(false)}
                    loading={joinLoading}
                    value={mintCertificate}
                    setValue={setMintCertificate}
                /> : null}
                <div className={styles.box}>
                    <h1 className={styles.title}>{guild? guild.name : "..."}</h1>

                    <img className={styles.profilepicture} src="/illustrations/warrior1.webp" alt="A warrior" />

                    <h2 className={styles.subtitle}>Description</h2>

                    <div className={styles.description}>
                        <p className={styles.data_text}>
                            Titans Of The Dark Circle is a guild on Eykar that allows the sharing of
                            resources between players. Members are allowed to battle, set up plots
                            where amounts of resouces allow you to do so.
                        </p>
                    </div>

                    <h2 className={styles.subtitle}>Actions</h2>

                    <div className={styles.actions}>
                        <p className={styles.data_text}>
                            This guild requires you to be whitelisted before joining.
                        </p>
                        <div className={styles.action_buttons}>
                            <button className={styles.button}>
                                <svg className={styles.icon} fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 13h6m-3-3v6m5 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"></path></svg>
                                <p className={styles.button_text}>Request Whitelist</p>
                            </button>
                            <button 
                                className={styles.button}
                                disabled={joinButtonDisabled}
                                onClick={() => {
                                    joinInvoke({
                                        args: [],
                                        metadata: { 
                                            method: 'join', 
                                            message: 'join the guild' 
                                        }
                                    })
                                    setJoinDialogToggled(true)
                                    }
                                }
                            >
                                <svg className={styles.icon} fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M18 9v3m0 0v3m0-3h3m-3 0h-3m-2-5a4 4 0 11-8 0 4 4 0 018 0zM3 20a6 6 0 0112 0v1H3v-1z"></path></svg>
                                <p className={styles.button_text}>Join</p>
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    )
}