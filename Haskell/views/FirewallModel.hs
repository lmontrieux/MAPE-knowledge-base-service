{-# LANGUAGE TemplateHaskell
, TypeFamilies #-}

module FirewallModel (
  ChangeView(..)
  , Rule(..)
  , View(..)
  ) where

import Generics.BiGUL.TH
import GHC.Generics

data ChangeView = ChangeView {
  current :: [Rule]
  , additions :: [Rule]
  , deletions :: [Rule]
  } deriving (Show, Eq)

data View = View {
  rules :: [Rule]
  } deriving (Show, Eq)

data Rule = Rule {
  securityGroupRefFrom :: String,
  securityGroupRefTo :: String,
  port :: Int,
  protocol :: String
  } deriving (Show, Eq)

deriveBiGULGeneric ''ChangeView
deriveBiGULGeneric ''View
deriveBiGULGeneric ''Rule
