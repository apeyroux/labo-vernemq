{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE DeriveGeneric #-}

import GHC.Generics
import Web.Scotty
import Data.Aeson
import Data.Text.Lazy as TL

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

instance FromJSON OnPublish where
  parseJSON = withObject "OnPublish" $ \v -> OnPublish
        <$> v .:? "username"
        <*> v .: "mountpoint"
        <*> v .: "client_id"
        <*> v .: "qos"
        <*> v .: "topic"
        <*> v .: "payload"
        <*> v .: "retain"

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
            text $ TL.pack $ opPayload op
          Nothing -> do
            liftAndCatchIO $ print b
            text "cant decode body"
      _ -> text "not publish event" --
