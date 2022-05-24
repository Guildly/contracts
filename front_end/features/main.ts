import warrior1 from '../public/illustrations/warrior1.webp'
import warrior2 from '../public/illustrations/warrior2.webp'
import deploymentsConfig from '../deployments-config.json'
import { StaticImageData } from 'next/image'

export type Guild = {
    address: string
    name: string
    image: string | StaticImageData
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
            image: warrior1,
            members: 47,
            games: ["Age Of Eykar"],
            slug: "titans-of-the-dark-circle",
        },
        {
            address: testGuild1Address,
            name: "Warriors Of The Mystic Mountain",
            image: warrior2,
            members: 20,
            games: ["Age Of Eykar"],
            slug: "warriors-of-the-mystic-mountain"
        }
    ]


    return { supportedGuilds }

}