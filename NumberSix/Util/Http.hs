-- | HTTP utility functions
--
module NumberSix.Util.Http
    ( httpGet
    , httpScrape
    , nextTag
    , nextTagText
    , urlEncode
    ) where

import Control.Applicative ((<$>))
import Control.Monad.Trans (liftIO)
import Data.List (isPrefixOf)

import qualified Codec.Binary.UTF8.String as Utf8
import qualified Codec.Binary.Url as Url
import Network.HTTP (getRequest, getResponseBody)
import Network.Browser (browse, request, setAllowRedirects)
import Text.HTML.TagSoup

import NumberSix.Irc

-- | Perform an HTTP get request and return the response body. The response body
-- is limited to 4096 characters, for security reasons.
--
httpGet :: String      -- ^ URL
        -> Irc String  -- ^ Response body
httpGet url = liftIO $ do
    (_, response) <- browse $ do
        setAllowRedirects True
        request $ getRequest url'
    fmap (take 4096) $ getResponseBody $ Right response
  where
    url' = if "http://" `isPrefixOf` url then url else "http://" ++ url

-- | Perform an HTTP get request, and scrape the body using a user-defined
-- function.
--
httpScrape :: String               -- ^ URL
           -> ([Tag String] -> a)  -- ^ Scrape function
           -> Irc a                -- ^ Result
httpScrape url f = f . parseTags <$> httpGet url

-- | Get the tag following a certain tag
--
nextTag :: [Tag String] -> Tag String -> Maybe (Tag String)
nextTag tags tag = case dropWhile (~/= tag) tags of
    (_ : x : _) -> Just x
    _ -> Nothing

-- | Get the text chunk following an opening tag with the given name
--
nextTagText :: [Tag String] -> String -> Maybe String
nextTagText tags name = do
    tag <- nextTag tags (TagOpen name [])
    case tag of TagText t -> return t
                _ -> Nothing

-- | Encode a String to an URL
--
urlEncode :: String -> String
urlEncode = Url.encode . Utf8.encode
