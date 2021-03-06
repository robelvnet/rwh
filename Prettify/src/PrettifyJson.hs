module PrettifyJson
  (
    renderJVal
  ) where

import Numeric(showHex)
import Data.Char(ord)
import Data.Bits(shiftR, (.&.))

import SimpleJson(JVal(..))
import Prettify

renderJVal :: JVal -> Doc
renderJVal (JStr x) = string x
renderJVal (JNum x) = double x
renderJVal (JBool True) = text "true"
renderJVal (JBool False) = text "false"
renderJVal (JNull) = text "null"
renderJVal (JArr x) = series '[' ']' renderJVal x
renderJVal (JObj x) = series '{' '}' field x
  where field (name, value) = string name
                           <> text ": "
                           <> renderJVal value

string :: String -> Doc
string = enclose '"' '"' . hcat . map oneChar

enclose :: Char -> Char -> Doc -> Doc
enclose left right x = char left <> x <> char right

oneChar :: Char -> Doc
oneChar c = case lookup c simpleEscapes of
              Just r -> text r
              Nothing | mustEscape c -> hexEscape c
                      | otherwise -> char c
              where mustEscape c = c < ' ' || c == '\x7f' || c > '\xff'

simpleEscapes :: [(Char, String)]
simpleEscapes = zipWith ch "\b\n\f\r\t\\\"/" "bnfrt\\\"/"
  where ch a b = (a, ['\\',b])

smallHex :: Int -> Doc
smallHex x = text "\\u"
          <> text (replicate (4 - length h) '0')
          <> text h
      where h = showHex x ""

astral :: Int -> Doc
astral n = smallHex (a + 0xd800) <> smallHex (b + 0xdc00)
  where a = (n `shiftR` 10) .&. 0x3ff
        b = n .&. 0x3ff

hexEscape :: Char -> Doc
hexEscape c
    | d < 0x10000 = smallHex d
    | otherwise = astral (d - 0x10000)
  where d = ord c

series :: Char -> Char -> (a -> Doc) -> [a] -> Doc
series open close item = enclose open close
                       . fsep . punctuate (char ',') . map item
