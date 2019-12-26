module Y2019.Day19 (parts) where

import Util.InstructionSet
import Util.Program

import Control.Applicative
import Control.Monad
import Control.Monad.Trans.Maybe
import Control.Monad.Trans.Class
import Data.Bool
import Data.Function
import Data.List
import Data.Maybe
import Debug.Trace

import qualified Draw
import           Data.List.Split   (chunksOf)
import Control.Monad
import Control.Monad.Trans.Maybe


findM :: (Monad m) => (a -> m (Maybe b)) -> [a] -> m (Maybe b)
findM f = runMaybeT . msum . map (MaybeT . f)


parts :: [((String -> IO String), Maybe String)]
parts = [ (part1, Just "171")
        , (part2, Just "9741242")
        ]


part1 input = do status <- program input >>= beamGrid
                 return . show . length $ filter (== True) status
  where
    width = [0 .. 49]
    beamGrid prog = sequence [beam prog x y | x <- width, y <- width]


-- Strategy
--   1. Binary-search the min/max Y values at a known X value.
--   2. The beam is bounded by two rays eminating from the origin. Use these two
--      Y values to calculate the angle of these two rays.
--   3. Use the magic of geometry to figure out where the solution ought to be.
--   4. Due to integer division, we likely overshot the true solution, so check
--      all the neighbors toward the origin.
part2 input = do prog <- program input
                 (x,y) <- fromJust <$> findAngles resolution prog
                          >>= return . calculateXY (fromIntegral squareLen)

                 (x',y') <- walkBack prog squareLen (ceiling x, ceiling y)
                 return . show $ outputCode x' y'
  where
    resolution = 120
    squareLen  = 100
    outputCode x y = x * 10000 + y


program = fmap (Program aoc19Set) . parseRAM


-- | Due to the "pixelated" shape of the beam, the calculated solution will
--   overestimate the true solution. Test the neighbors closer to the origin to
--   find the true solution.
walkBack :: Program' -> Int -> (Int,Int) -> IO (Int,Int)
walkBack p len (x,y) =
    runMaybeT (foldl' (<|>) empty probes) >>= maybe (pure (x,y)) (walkBack p len)
  where
    coords = init [(x-x', y-y') | x' <- n, y' <- n] where n = [2, 1, 0]

    probes :: [MaybeT IO (Int,Int)]
    probes = probeNeighbor <$> coords
    probeNeighbor (x',y') = liftIO fire >>= guard >> return (x',y')
      where fire = beamSquare len x' y' p


-- | Given a square with @squareLen@ sides, return the coordinates of its corner
--   closest to origin, where it can fit within the beam bounded by @thetaA@ and
--   @thetaB@.
calculateXY :: Float -> (Float, Float) -> (Float,Float)
calculateXY squareLen (thetaA, thetaB) = (x,y)
  where
    y   = (hyp / (sin $ pi/2)) * sin thetaA
    x   = (hyp * cos thetaA) - squareLen
    hyp = ((squareLen + x') / (sin $ thetaB - thetaA)) * (sin $ pi - thetaB)
    x'  = (squareLen / sin thetaB) * sin (pi/2 - thetaB)


data EdgeDir = Up | Down deriving Eq


-- | At a given X value, search for the Y coordinates that bound the beam and
--   return their heading.
findAngles :: Int -> Program' -> IO (Maybe (Float, Float))
findAngles x prog = do
    mid <- fromJust <$> findMiddle 0 limitY
    bot <- findEdge Down 0   mid
    top <- findEdge Up   mid limitY
    return $ (,) <$> (angle <$> bot) <*> (angle <$> top)
  where
    limitY = x * 2
    angle y = atan $ ((/) `on` fromIntegral) y x

    findMiddle min max
      | max - min == 1 = return Nothing
      | otherwise = do
          midResult <- test midway
          if midResult
            then return $ Just midway
            else findMiddle min midway >>=
                 maybe (findMiddle midway max) (return . Just)
      where
        midway = (min + max) `div` 2
        test y = beam prog x y

    findEdge dir min max
      | max - min == 1 =
        liftA2 ((bool Nothing success .)  . (/=)) (beamX min) (beamX max)
      | otherwise =
        beamX midway >>= bool searchIn searchOut
      where
        beamX     = beam prog x
        success   = Just $ bool max min (dir == Up)
        midway    = (min + max) `div` 2
        findEdge' = uncurry $ findEdge dir
        searchOut = findEdge' $ bool (min, midway) (midway, max) (dir == Up)
        searchIn  = findEdge' $ bool (midway, max) (min, midway) (dir == Up)


-- | Is the beam having an effect at the given coordinates?
beam :: Program' -> Int -> Int -> IO Bool
beam prog x y =
    all (== 1) <$> evalStateT (execute >> pop) (load' prog){ stdin = [x,y] }


-- | Test if a square of the given size fit inside the beam at these coordinates.
beamSquare :: Int -> Int -> Int -> Program' -> IO Bool
beamSquare size x y prog = and <$> scatter
  where
    scatter = sequence [beam prog x y | (x,y) <- coords]
    coords  = [(x+n,y), (x,y+n)]
    n       = size - 1
