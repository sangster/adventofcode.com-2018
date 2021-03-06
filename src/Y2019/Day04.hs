module Y2019.Day04 (parts) where

import Control.Monad  (liftM2)
import Data.List      (group)
import Parser


parts = ( (part1, Just "2050")
        , (part2, Just "1390")
        , parse range
        )


part1 :: [Int] -> String
part1 passwords = show $ length valids
  where
    valids    = filter isValid passwords


part2 :: [Int] -> String
part2 passwords = show $ length valids
  where
    valids    = filter (liftM2 (&&) isValid isValid') passwords
    isValid'  = (any $ (== 2) . length) . group . digits


range :: Parser [Int]
range = do { a <- natural; char '-'; b <- natural; pure [a .. b] }


digits :: Int -> [Int]
digits 0 = []
digits n = n `mod` 10 : digits (n `div` 10)


isValid :: Int -> Bool
isValid x
  | x < 100000 || x > 999999       = False
  | not $ any (uncurry (==)) pairs = False
  | any (uncurry (<))  pairs       = False
  | otherwise                      = True
  where
    pairs   = zip digits' $ tail digits'
    digits' = digits x
