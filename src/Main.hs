{-# LANGUAGE OverloadedStrings #-}

import Web.Scotty

import Data.Monoid (mconcat)

-- https://docs.vernemq.com/plugindevelopment/webhookplugins
main = scotty 3000 $
  post "/inventories" $ do
    b <- body
    h <- header "vernemq-hook"
    liftAndCatchIO $ print b
    liftAndCatchIO $ print h
    text "ok"
