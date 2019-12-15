module Day01 (parts, part1, part2) where

import System.Environment (getArgs)
import qualified Data.IntSet as IntSet


parts = [part1, part2]


{- converts a textual number like -123, +123 into an Int -}
parseSigned :: [Char] -> Int
parseSigned ('+' : str) =     read str
parseSigned ('-' : str) = 0 - read str
parseSigned str         = error ("'" ++ str ++ "' is not a signed integer")


part1 :: String -> String
part1 content =
    show $ sum . (map parseSigned) . lines $ content


type FreqQueue = [Int]
data FreqCounter = FreqCounter !IntSet.IntSet FreqQueue !Int


findRepeat :: FreqQueue -> Int
findRepeat numbers =
    findRepeat' (FreqCounter (IntSet.singleton 0) (cycle numbers) 0)
  where
    findRepeat' (FreqCounter history (x:xs) freq)
        | IntSet.member freq' history = freq'
        | otherwise = findRepeat' (FreqCounter history' xs freq')
      where freq'    = freq + x
            history' = IntSet.insert freq' history


part2 :: String -> String
part2 content = show $ findRepeat numbers
  where numbers = (map parseSigned) . lines $ content :: FreqQueue