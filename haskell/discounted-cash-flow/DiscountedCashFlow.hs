{-# LANGUAGE PostfixOperators #-}

module Main where

import Steshaw
import System (getArgs, getProgName)
import Prelude hiding (catch)
import Data.List (intersperse)
import Control.Exception (try, catch, tryJust)
import Control.Monad (mapM_, join)
import Control.Monad.Fix (fix)

(%) n = n / 100.0

min_years = 1
max_years = 250
step = 1

weekly_rent = 400.00

usage = do
  progName <- getProgName
  putStrLn ("usage: " ++ progName ++ " <min-interest-rate> <max-interest-rate>\n\n" ++
    "  min-interest-rate   low end of the range of the prevailing risk-free interest rate\n" ++
    "  max-interest-rate   top end of the range of the prevailing risk-free interest rate\n\n" ++
    " e.g. DiscountedCashFlow 3.0 8.0")

print_dcf_at_8 = printDCF (8.0 %) $> last $> snd $> print

main =
  do
  args <- getArgs
  case args of
    [min_rate, max_rate] ->
      case (reads (args !! 0), reads (args !! 1)) :: ([(Double, String)], [(Double, String)]) of
        ([(min_rate, "")], [(max_rate, "")]) -> printTable min_rate max_rate
        otherwise -> usage
    otherwise -> usage

third (a,b,c) = c

dot2 :: Double -> Double
dot2 n = n $> (* 10) $> truncate $> fromIntegral $> (/ 10)

floats min max =
  if min < (max+0.1) then (dot2 min):(floats (min + 0.1) max)
  else []

showResult :: (Double, Integer, Double) -> String
showResult (a, _, c) = (show (dot2 (a*100))) ++ "%: " ++ (double2dollar c)

genTable min_rate max_rate =
  floats min_rate max_rate $> map (%) $> map (\rate -> computeStream rate $> last)

printTable min_rate max_rate =
  genTable min_rate max_rate $> map showResult $> mapM_ putStrLn

printDCF risk_free_interest_rate =
  ([min_years,min_years+step..max_years] // \years -> [1..years]
    // (\year -> weekly_rent * 52 / (1 + risk_free_interest_rate) ^ year)
    $> \ns -> (years, sum ns $> (/ 1000) $> round $> show $> (++ "k")))

computeStream risk_free_interest_rate =
  ([min_years,min_years+step..max_years] // \years -> [1..years]
    // (\year -> weekly_rent * 52 / (1 + risk_free_interest_rate) ^ year)
    $> \ns -> (risk_free_interest_rate, years, sum ns))

computeDCF risk_free_interest_rate = computeStream risk_free_interest_rate $> last $> third

separate1000s' :: Integer -> [Integer]-> [Integer]
separate1000s' n ns =
  if (n `div` 1000) > 0 then separate1000s' (n `div` 1000) ((n `mod` 1000):ns)
  else n:ns

separate1000s :: Integer -> [Integer]
separate1000s n = separate1000s' n []

separate1000s_on_double :: Double -> [Integer]
separate1000s_on_double n = let r = round n in separate1000s r

fillto3 s = if length s < 3 then fillto3 ('0':s) else s

asdf xs = (xs !! 0) : (map fillto3 (tail xs))

-- Don't fillto3 the first number!
double2dollar :: Double -> String
double2dollar n =
  let ns = separate1000s_on_double n 
  in "$" ++ ns $> map show $> asdf $> intersperse "," $> join

double2k :: Double -> String
double2k n = n $> round $> \n -> "$" ++ show n ++ "k"

{-
  $> \ns -> (years, sum ns $> (/ 1000) $> round $> \n -> "$" ++ show n ++ "k"))
  $> mapM_ (\(num, value) -> putStrLn ((show num) ++ ": " ++ value))
-}

{-
(10, 200,000.00)
(20, 350,000.00)
(30, 510,000.00)
(40, 519,000.00)
(50, 519,000.00)
-}

--calc :: Float -> Float
--calc years = ([1..years] // (\year -> weekly_rent * 52 / ((1.0 + risk_free_interest_rate) ^ year)) ) $> sum