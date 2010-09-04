module NumberSix.Handlers.Seen
    ( handler
    ) where

import Control.Applicative ((<$>))

import NumberSix.Irc
import NumberSix.Util
import NumberSix.Util.Redis

handler :: Handler
handler = Handler
    { handlerName = "seen"
    , handlerHooks = [storeHook, loadHook]
    }

storeHook :: Irc ()
storeHook = onCommand "privmsg" $ do
    sender <- getSender
    time <- prettyTime
    text <- getMessageText
    let lastSeen = (time, text)
    setItem sender lastSeen

loadHook :: Irc ()
loadHook = onBangCommand "!seen" $ do
    (who, _) <- breakWord <$> getBangCommandText
    item <- getItem who
    case item of
        Just (time, text) -> writeChannelReply $
            "I last saw " ++ who ++ " on " ++ time
                          ++ " saying: " ++ text
        _ -> writeChannelReply $ "I ain't never seen " ++ who
