{-# LANGUAGE OverloadedStrings #-}

module HSL.Json (json, json2, json3, jsonN) where

import           Control.Applicative
import           Control.Monad (foldM)

import           Data.Aeson hiding (json)
import qualified Data.Aeson as Ae
import qualified Data.Aeson.Types as AT
import qualified Data.Attoparsec.Lazy as AL
import qualified Data.Attoparsec.Text as A
import qualified Data.HashMap.Strict as HashMap
import           Data.Maybe
import qualified Data.Text as T
import qualified Data.Text.Lazy as TL
import qualified Data.Text.Lazy.Encoding as TLE
import           Data.Vector ((!))

import           HSL.IO (unsafePutErr)


type Getter = (Value -> AT.Parser Value)


parseQuery :: A.Parser [Getter]
parseQuery = do
    A.skipSpace
    end <- A.atEnd
    if end then return []
           else do g <- parseGetter
                   rest <- parseQuery
                   return $ g:rest


parseGetter :: A.Parser Getter
parseGetter = mkIndex <$> A.decimal <|>
              mkLookup <$> readKey
  where
    mkLookup k = withObject "object" $ maybe err return . HashMap.lookup k
      where err = error $ T.unpack k
    mkIndex i = withArray "array" (\a -> return (a ! i))


readKey :: A.Parser T.Text
readKey = fmap (T.pack . qq . T.unpack) $ A.scan '_' keyEnd
  where
    keyEnd s c = if c == ' ' && s /= '\\' then Nothing else Just c
    qq [] = []
    qq [x] = [x]
    qq (x:y:cx) = if x == '\\' then y : qq cx else x : qq (y:cx)


prepQuery :: T.Text -> [Getter]
prepQuery q = case A.parseOnly parseQuery q of Right res -> res
                                               Left e -> error e


drill :: AT.Value -> [Getter] -> Result Value
drill top = AT.parse (foldM (\v f -> f v) top)


unsafeResult :: Result a -> Maybe a
unsafeResult res = case res of Success v -> Just v
                               Error e -> unsafePutErr e Nothing


json :: FromJSON a => a -> T.Text -> [T.Text] -> [a]
json _ q = jsonN (fromJSON . head) [q]


json2 :: (FromJSON a, FromJSON b) =>
         (a, b) -> T.Text -> T.Text -> [T.Text] -> [(a, b)]
json2 _ q1 q2 = jsonN cast [q1, q2]
    where cast [v1, v2] = (,) <$> fromJSON v1 <*> fromJSON v2


json3 :: (FromJSON a, FromJSON b, FromJSON c) =>
         (a, b, c) ->
         T.Text ->
         T.Text ->
         T.Text ->
         [T.Text] ->
         [(a, b, c)]
json3 _ q1 q2 q3 = jsonN cast [q1, q2, q3]
    where cast [v1, v2, v3] = (,,) <$> fromJSON v1
                                   <*> fromJSON v2
                                   <*> fromJSON v3


jsonN :: ([Value] -> Result a) -> [T.Text] -> [T.Text] -> [a]
jsonN cast qN = catMaybes . map (unsafeResult . getValues)
  where qs = map prepQuery qN
        getValues ins = do let dec = TLE.encodeUtf8 $ TL.fromStrict ins
                           top <- case AL.parse Ae.json dec of
                                       AL.Done _ a -> Success a
                                       AL.Fail _ _ e -> Error e
                           sequence (map (drill top) qs) >>= cast
