import Link from 'next/link';
import styles from '../styles/components/GuildBox.module.css'
import { useGuildsContract, useShareCertificate } from '../hooks/guilds';
import { useStarknet, useStarknetCall } from '@starknet-react/core';
import { feltToString } from "../utils/felt";
import { uint256 } from "starknet"
import { toBN } from 'starknet/dist/utils/number';

export default function GuildBox({ guild }) {

    const { account } = useStarknet();
    const { contract: guildContract } = useGuildsContract(guild);
    const { contract: certificateContract } = useShareCertificate();


    const guildContractAddress = guild;

    const { data: nameData } = useStarknetCall({ contract: guildContract, method: 'name', args: [] });
    const { data: extensionsData } = useStarknetCall({ contract: guildContract, method: 'get_extensions_number', args: [] });

    const { data: titleData } = useStarknetCall({ contract: certificateContract, method: 'get_value', args: [account, guildContractAddress, 0] });
    const { data: certificate_id } = useStarknetCall({ contract: certificateContract, method: 'get_certificate_id', args: [account, guildContract ? guildContract.address : 0] });
    const { data: tokenData } = useStarknetCall({ contract: certificateContract, method: 'get_shares', args: [certificate_id ? certificate_id.token_id : 0] });
    const members = 47;
    const fundsValue = 0;

    return (
        <Link href={"/panel/" + guildContractAddress}>
            <div className={styles.box}>
                <img className={styles.img} src={guild==0 ? "/illustrations/warrior2.webp": "/illustrations/warrior1.webp"} alt="A warrior" />
                <div className={styles.content}>
                    <h1 className={styles.name}>{nameData ? feltToString(nameData.name) : 
                                                guild==0 ? "Titans Of The Dark Circle": "Warriors Of The Mystic Mountain"}</h1>
                    <div className={styles.description}>

                        <div className={styles.descline} >
                            <svg className={styles.icon} fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path d="M10.394 2.08a1 1 0 00-.788 0l-7 3a1 1 0 000 1.84L5.25 8.051a.999.999 0 01.356-.257l4-1.714a1 1 0 11.788 1.838L7.667 9.088l1.94.831a1 1 0 00.787 0l7-3a1 1 0 000-1.838l-7-3zM3.31 9.397L5 10.12v4.102a8.969 8.969 0 00-1.05-.174 1 1 0 01-.89-.89 11.115 11.115 0 01.25-3.762zM9.3 16.573A9.026 9.026 0 007 14.935v-3.957l1.818.78a3 3 0 002.364 0l5.508-2.361a11.026 11.026 0 01.25 3.762 1 1 0 01-.89.89 8.968 8.968 0 00-5.35 2.524 1 1 0 01-1.4 0zM6 18a1 1 0 001-1v-2.065a8.935 8.935 0 00-2-.712V17a1 1 0 001 1z"></path></svg>
                            You hold the title of {titleData ? feltToString(titleData.value) : 
                                guild==1 ? "Member": "Owner"}
                        </div>
                        {guild==0 ? (
                            <div className={styles.descline} >
                                <svg className={styles.icon} fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path fillRule="evenodd" d="M10 2a1 1 0 00-1 1v1a1 1 0 002 0V3a1 1 0 00-1-1zM4 4h3a3 3 0 006 0h3a2 2 0 012 2v9a2 2 0 01-2 2H4a2 2 0 01-2-2V6a2 2 0 012-2zm2.5 7a1.5 1.5 0 100-3 1.5 1.5 0 000 3zm2.45 4a2.5 2.5 0 10-4.9 0h4.9zM12 9a1 1 0 100 2h3a1 1 0 100-2h-3zm-1 4a1 1 0 011-1h2a1 1 0 110 2h-2a1 1 0 01-1-1z" clipRule="evenodd"></path></svg>
                                You own {tokenData ? "7" : "5"} tokens
                            </div>
                        ): (<></>)}

                        <div className={styles.descline} >
                            <svg className={styles.icon} fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path d="M13 6a3 3 0 11-6 0 3 3 0 016 0zM18 8a2 2 0 11-4 0 2 2 0 014 0zM14 15a4 4 0 00-8 0v3h8v-3zM6 8a2 2 0 11-4 0 2 2 0 014 0zM16 18v-3a5.972 5.972 0 00-.75-2.906A3.005 3.005 0 0119 15v3h-3zM4.75 12.094A5.973 5.973 0 004 15v3H1v-3a3 3 0 013.75-2.906z"></path></svg>
                            There are {members} members of the guild
                        </div>

                        {/* <div className={styles.descline} >
                            <svg className={styles.icon} fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path d="M8.433 7.418c.155-.103.346-.196.567-.267v1.698a2.305 2.305 0 01-.567-.267C8.07 8.34 8 8.114 8 8c0-.114.07-.34.433-.582zM11 12.849v-1.698c.22.071.412.164.567.267.364.243.433.468.433.582 0 .114-.07.34-.433.582a2.305 2.305 0 01-.567.267z"></path><path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm1-13a1 1 0 10-2 0v.092a4.535 4.535 0 00-1.676.662C6.602 6.234 6 7.009 6 8c0 .99.602 1.765 1.324 2.246.48.32 1.054.545 1.676.662v1.941c-.391-.127-.68-.317-.843-.504a1 1 0 10-1.51 1.31c.562.649 1.413 1.076 2.353 1.253V15a1 1 0 102 0v-.092a4.535 4.535 0 001.676-.662C13.398 13.766 14 12.991 14 12c0-.99-.602-1.765-1.324-2.246A4.535 4.535 0 0011 9.092V7.151c.391.127.68.317.843.504a1 1 0 101.511-1.31c-.563-.649-1.413-1.076-2.354-1.253V5z" clipRule="evenodd"></path></svg>
                            The guild&apos;s funds are estimated at ${fundsValue}
                        </div> */}

                        <div className={styles.descline} >
                            <svg className={styles.icon} fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM4.332 8.027a6.012 6.012 0 011.912-2.706C6.512 5.73 6.974 6 7.5 6A1.5 1.5 0 019 7.5V8a2 2 0 004 0 2 2 0 011.523-1.943A5.977 5.977 0 0116 10c0 .34-.028.675-.083 1H15a2 2 0 00-2 2v2.197A5.973 5.973 0 0110 16v-2a2 2 0 00-2-2 2 2 0 01-2-2 2 2 0 00-1.668-1.973z" clipRule="evenodd"></path></svg>
                            This guild is connected to {extensionsData ? extensionsData.nb.toString() : "2"} games
                        </div>

                    </div>
                </div>
            </div>
        </Link>
    );

}
