{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}

import Data.Aeson
import Data.Text.Lazy as TL
import GHC.Generics
import Network.HTTP.Simple
import Web.Scotty
import qualified Data.ByteString.Base64 as B64
import qualified Data.ByteString.Char8 as BSC
import qualified Data.ByteString.Lazy as LBS


import Data.Monoid (mconcat)

-- {\"username\":null,\"mountpoint\":\"\",\"client_id\":\"mosqpub|6381-xps15.px.i\",\"qos\":0,\"topic\":\"inventories/test\",\"payload\":\"dGVzdA==\",\"retain\":false}
data OnPublish = OnPublish {
  opUserName :: Maybe String
  , opMountPoint :: String
  , opClientID :: String
  , opQOS :: Integer
  , opTopic :: String
  , opPayload :: String
  , opRetain :: Bool
  } deriving (Show, Generic)

data Phone = Phone {
  phoneIMEI :: String
  } deriving (Show, Generic)

instance FromJSON Phone where
  parseJSON = withObject "Phone" $ \v -> Phone
    <$> v .: "imei"

instance ToJSON Phone

instance FromJSON OnPublish where
  parseJSON = withObject "OnPublish" $ \v -> OnPublish
        <$> v .:? "username"
        <*> v .: "mountpoint"
        <*> v .: "client_id"
        <*> v .: "qos"
        <*> v .: "topic"
        <*> v .: "payload"
        <*> v .: "retain"

instance ToJSON OnPublish

-- Just "on_publish"
-- https://docs.vernemq.com/plugindevelopment/webhookplugins
main = scotty 3000 $
  post "/inventories" $ do
    h <- header "vernemq-hook"
    case h of
      Just "on_publish" -> do
        b <- body
        case decode b :: Maybe OnPublish of
          Just op -> do
            liftAndCatchIO $ print op
            -- put to couchdb
            request' <- parseRequest "POST http://127.0.0.1"
            case B64.decode (BSC.pack $ opPayload op) of
              Left err -> do
                liftAndCatchIO $ print err
                text $ TL.pack err
              Right rawjs -> 
                case decode (LBS.fromStrict rawjs) :: Maybe Phone of
                  Just p -> do
                    -- insert, for up add If-Match heaer :
                    -- https://docs.couchdb.org/en/stable/api/document/common.html
                    let request
                          = setRequestMethod "PUT"
                          $ setRequestPath "/phones/00001"
                          $ setRequestBodyJSON p
                          $ setRequestPort 5984
                          $ request'
                    response <- httpLBS request
                    liftAndCatchIO $ print response
                    text $ TL.pack $ opPayload op
                  Nothing -> do
                    liftAndCatchIO $ print rawjs
                    liftAndCatchIO $ print "cant decode phone"
                    text $ TL.pack $ opPayload op                    
          Nothing -> do
            liftAndCatchIO $ print b
            text "cant decode body"
      _ -> text "not publish event" --
