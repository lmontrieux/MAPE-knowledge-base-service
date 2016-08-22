{-# LANGUAGE TemplateHaskell,
TypeFamilies #-}

module RedundancyBX(
  instUpd,
  instListAlign,
  redundancyUpd,
  get,
  put
  ) where

import Generics.BiGUL.AST
import Generics.BiGUL.Error
import Generics.BiGUL.Interpreter
import Language.Haskell.TH as TH hiding (Name)
import Generics.BiGUL.TH
import Control.Monad
import Data.Char
import Data.List
import GHC.Generics
import Control.Arrow
import Data.Maybe
import Utils
import qualified SourceModel as S
import qualified RedundancyModel as V

redundancyUpd :: BiGUL S.Model V.View
redundancyUpd = $(update [p| V.View {
                             V.instances = instances
                     }|] [p| S.Model {
                             S.instances = instances
                     }|] [d| instances = instListAlign
                      |])

instUpd :: BiGUL S.Instance V.Instance
instUpd = $(update [p| V.Instance {
        V.instID = instID
        , V.securityGroupRef = securityGroupRef
        , V.status = status
    }|] [p| S.Instance {
        S.instID = instID
        , S.securityGroupRef = securityGroupRef
        , S.instStatus = status
    }|] [d| instID = Replace;
            securityGroupRef = Replace;
            status = Replace
    |])

instListAlign :: BiGUL [S.Instance] [V.Instance]
instListAlign = align (const True)
  (\ s v -> S.instID s == V.instID v)
  ($(update [p| v |] [p| v |] [d| v = instUpd |]))
  (\v -> S.Instance {
      S.instID = V.instID v
      , S.instType = "t2.micro"
      , S.instStatus = 1
      , S.ami = "0000"
      , S.state = 0
      , S.instResponseTime = -1
      , S.load = 0.00
      , S.securityGroupRef = V.securityGroupRef v
      })
  (\s -> Just S.Instance {
      S.instID = S.instID s
      , S.instType = S.instType s
      , S.load = S.load s
      , S.instStatus = 2
      , S.ami = S.ami s
      , S.state = S.state s
      , S.instResponseTime = S.instResponseTime s
      , S.securityGroupRef = S.securityGroupRef s
      })
