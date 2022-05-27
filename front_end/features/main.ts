import deploymentsConfig from '../deployments-config.json'
import { StaticImageData } from 'next/image'

export type Guild = {
    address: string
    name: string
    image: string
    members: number
    games: Array<String>
    slug: string
}

export const Main = () => {

    const testGuild1Address = deploymentsConfig["networks"]["goerli"]["test_guild_1"]

    const supportedGuilds: Array<Guild> = [
        {
            address: testGuild1Address,
            name: "Titans Of The Dark Circle",
            image: '/illustrations/warrior2.webp',
            members: 47,
            games: ["Age Of Eykar"],
            slug: "titans-of-the-dark-circle",
        },
        {
            address: testGuild1Address,
            name: "Warriors Of The Mystic Mountain",
            image: '/illustrations/warrior1.webp',
            members: 20,
            games: ["Age Of Eykar"],
            slug: "warriors-of-the-mystic-mountain"
        }
    ]


    return { supportedGuilds }

}