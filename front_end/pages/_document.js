import { Html, Head, Main, NextScript } from 'next/document'

export default function Document() {
    return (
        <Html>
            <Head />
            <title>Guilds</title>

            <meta charSet="utf-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1" />
            <meta name="theme-color" content="#101D30" />
            <meta property="og:site_name" content="Connect players to connect games" />
            <meta property="og:title" content="Guilds 🛡" />
            <meta property="og:type" content="website" />
            <meta property="og:description" content="Organize your team to conquer all the games of StarkNet" />
            <meta property="og:url" content="%PUBLIC_URL%" />
            <meta property="og:image" content="%PUBLIC_URL%/logo.svg" />
            <meta name="description" content="Organize your team to conquer all the games of StarkNet" />

            <link rel="icon" href="/favicon.svg" />
            <body className="default_background_color">
                <Main />
                <NextScript />
            </body>
        </Html>
    )
}