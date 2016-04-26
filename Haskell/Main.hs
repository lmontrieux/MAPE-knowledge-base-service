{-# LANGUAGE TemplateHaskell
, TypeFamilies, OverloadedStrings #-}

module Main where

import System.Environment
import Generics.BiGUL.TH
import GHC.Generics
import Data.Aeson
import Data.Text
import Control.Applicative
import Control.Monad
import qualified Data.ByteString.Lazy as B
import SourceModel
import qualified AutoScalingBX as ASBX
import qualified FirewallBX as FWBX
import qualified RedundancyBX as REDBX
import qualified ExecutionBX as EXBX
import qualified AutoScalingModel as ASV
import qualified FirewallModel as FWV
import qualified RedundancyModel as REDV
import qualified ExecutionModel as EXV

sourceFile :: FilePath
sourceFile = "source.json"

getJSON :: IO B.ByteString
getJSON = B.readFile sourceFile

doGet bx source param = case bx of
  "autoScaling" -> case result of
    Right res -> encode res
    where result = (ASBX.get (ASBX.autoScalingUpd param) source)
  "redundancy" -> case result of
    Right res -> encode res
    where result = (REDBX.get REDBX.redundancyUpd source)
  "execution" -> encode (EXBX.getExecution source)

doASPut source view param = case result of
  Right res -> encode res
  where result = (ASBX.put (ASBX.autoScalingUpd param) source view)

doREDPut source view = case result of
  Right res -> encode res
  where result = (REDBX.put REDBX.redundancyUpd source view)

doEXPut source view = case result of
  Right res -> encode res
  where result = (EXBX.put EXBX.executionUpd source view)

-- arguments are:
-- dir: the direction, either get or put
-- bx: the name of the transformation
-- view: the filename of the view, expected to be in JSON
-- param: a parameter to pass to the bx (not all BX need this)
-- Example: ./Main get autoScaling as.json
main :: IO ()
main = do
  [dir, bx, view, param] <- getArgs
  putStrLn "Start"
  src <- (eitherDecode <$> getJSON) :: IO (Either String Model)
  case src of
    Left err -> putStrLn err
    Right source -> case dir of
      "get" -> do
        B.writeFile view (doGet bx source param)
        putStrLn "Done"
      "put" -> do
        putStrLn "put"
        case bx of
          "autoScaling" -> do
            putStrLn "autoscaling: reading JSON file"
            v <- (eitherDecode <$> (B.readFile view)) :: IO (Either String ASV.View)
            case v of
              Left err -> do
                putStrLn "JSON parse error"
                putStrLn err
              Right vw -> B.writeFile sourceFile (doASPut source vw param)
          "redundancy" -> do
            putStrLn "redundancy: reading JSON file"
            v <- (eitherDecode <$> (B.readFile view)) :: IO (Either String REDV.View)
            case v of
              Left err -> do
                putStrLn "JSON parse error"
                putStrLn err
              Right vw -> do
                putStrLn "redundancy: running put transformation and writing file"
                B.writeFile sourceFile (doREDPut source vw)
          "execution" -> do
            putStrLn "execution: reading JSON file"
            v <- (eitherDecode <$> (B.readFile view)) :: IO (Either String EXV.View)
            case v of
              Left err -> do
                putStrLn "JSON parse error"
                putStrLn err
              Right vw -> B.writeFile sourceFile (doEXPut source vw)


{-
Zhenjiang: the following two functions can be used to generate the Haskell
representations from the JSON representation of soruce/view for simple
testing of FirewallBX.hs.
-}

jsonSource2Haskell :: IO ()
jsonSource2Haskell = do
  src <- (eitherDecode <$> B.readFile "source.json") :: IO (Either String Model)
  case src of
    Right s -> putStrLn (show s)
    Left _  -> putStrLn "wrong in passing JSON"

jsonFirewallView2Haskell :: IO ()
jsonFirewallView2Haskell = do
  view <- (eitherDecode <$> B.readFile "firewall.json") :: IO (Either String FWV.View)
  case view of
    Right v -> putStrLn (show v)
    Left _  -> putStrLn "wrong in passing JSON"
