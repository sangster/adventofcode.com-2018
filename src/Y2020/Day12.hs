module Y2020.Day12 (parts) where

import Data.Bool (bool)
import Parser


parts :: [((String -> String), Maybe String)]
parts = [ (part1, Just "362")
        , (part2, Just "29895")
        ]


part1 input = show . manhattanDistance . fst
            $ foldl doNav ((0,0), East) navs
  where
    navs = parse (splitSome spaces nav) input
    doNav (xy,    b) (Turn d  ) = (xy, rotateDeg d b)
    doNav ((x,y), b) (Move d n) = (doMove d, b)
      where
        doMove East    = (x+n, y  )
        doMove South   = (x  , y-n)
        doMove West    = (x-n, y  )
        doMove North   = (x  , y+n)
        doMove Forward = doMove b


part2 input = show . manhattanDistance . fst
            $ foldl doNav ((0,0), (10,1)) navs
  where
    navs = parse (splitSome spaces nav) input

    doNav (xy,     wxy     ) (Turn d        ) = (xy, rotateWaypointDeg d wxy)
    doNav ((x, y), (wx, wy)) (Move Forward n) = ((x+wx*n, y+wy*n), (wx, wy))
    doNav (xy,     (wx, wy)) (Move d       n) = (xy, moveWaypoint d)
      where
        (wx', wy') = moveWaypoint d

        moveWaypoint East    = (wx+n, wy  )
        moveWaypoint South   = (wx  , wy-n)
        moveWaypoint West    = (wx-n, wy  )
        moveWaypoint North   = (wx  , wy+n)
        moveWaypoint _       = (wx  , wy  )


data Nav = Move Dir Int
         | Turn Int
         deriving (Eq, Show)


data Dir = East
         | South
         | West
         | North
         | Forward
         deriving (Bounded, Enum, Eq, Show)


nav :: Parser Nav
nav = move <|> turn


move :: Parser Nav
move = do d <- dir
          n <- natural
          pure $ Move d n
  where
    dir = (char 'E' >> pure East)
      <|> (char 'S' >> pure South)
      <|> (char 'W' >> pure West)
      <|> (char 'N' >> pure North)
      <|> (char 'F' >> pure Forward)


turn :: Parser Nav
turn = do r <- isRight
          n <- natural
          pure . Turn $ bool (360-n) n r
  where
    isRight = (char 'L' >> pure False)
          <|> (char 'R' >> pure True)


rotateDeg :: Int -> Dir -> Dir
rotateDeg 0   dir = dir
rotateDeg deg dir = rotateDeg (deg-90) (rotate dir)
  where
    rotate North = East
    rotate d     = succ d


rotateWaypointDeg :: Int -> (Int, Int) -> (Int, Int)
rotateWaypointDeg 0 xy = xy
rotateWaypointDeg d xy = rotateWaypointDeg (d-90) (rotate xy)
  where
    rotate (x,y) = (y, (x * (-1)))


manhattanDistance :: (Int, Int) -> Int
manhattanDistance (x, y) = abs x + abs y
