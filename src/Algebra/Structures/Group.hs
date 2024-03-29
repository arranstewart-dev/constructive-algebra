{-# LANGUAGE FlexibleInstances, UndecidableInstances #-}
module Algebra.Structures.Group
  ( Group(..)
  , propAssoc, propId, propInv, propGroup
  , AbelianGroup(..)
  , propComm, propAbelianGroup
  , sumGroup
  ) where

import qualified Algebra.Structures.CommutativeRing as R

import Test.QuickCheck
import Data.List

class Group a where
  (<+>) :: a -> a -> a
  zero  :: a
  neg   :: a -> a

propAssoc :: (Group a, Eq a) => a -> a -> a -> Bool
propAssoc a b c = (a <+> b) <+> c == a <+> (b <+> c)

propId :: (Group a, Eq a) => a -> Bool
propId a = a <+> zero == a && zero <+> a == a

propInv :: (Group a, Eq a) => a -> Bool
propInv a = neg a <+> a == zero && a <+> neg a == zero

propGroup :: (Group a, Eq a) => a -> a -> a -> Property
propGroup a b c = propAssoc a b c .&. propId a .&. propInv a

-- | Abelian groups:

class Group a => AbelianGroup a where

propComm :: (AbelianGroup a, Eq a) => a -> a -> Bool
propComm x y = x <+> y == y <+> x

propAbelianGroup :: (AbelianGroup a, Eq a) => a -> a -> a -> Property
propAbelianGroup a b c = propGroup a b c .&. propComm a b

sumGroup :: AbelianGroup a => [a] -> a
sumGroup xs = foldr (<+>) zero xs

-- | Pairs of groups:
instance (Group a, Group b) => Group (a,b) where
  zero            = (zero,zero)
  (a,b) <+> (c,d) = (a <+> c, b <+> d)
  neg (a,b)       = (neg a, neg b)


instance R.Ring a => Group a where
  (<+>) = (R.<+>) 
  zero  = R.zero
  neg   = R.neg

instance (Group a, R.Ring a) => AbelianGroup a

-------------------------------------------------------------------------------
-- Functions on groups:

-- | pow g n computes the n:th power of g, g^n
pow :: Group a => a -> Integer -> a
pow g 0 = zero
pow g n | n > 0     = g <+> pow g (n-1)
        | otherwise = pow (neg g) (abs n)

-- | gen g constructs the cyclic group <g> generated by g
gen :: (Group a, Eq a) => a -> [a]
gen g = reverse $ gen' 0 []
  where 
  gen' n xs | elem (pow g n) xs = xs
            | otherwise         = gen' (n+1) (pow g n : xs)

-- | Generalization for multiple generators, <S> where S = {g_1,g_2,...}
multiGen :: (Group a, Eq a) => [a] -> [a]
multiGen = nub . concatMap gen

order :: (Group a, Eq a) => a -> Int
order = length . gen

-- | Compute the right and left cosets of a subset hs in the group G with 
--   respect to an element g in G 
rightCoset :: Group a => [a] -> a -> [a]
rightCoset hs g = [ h <+> g | h <- hs ]

leftCoset :: Group a => a -> [a] -> [a]
leftCoset g hs = [ g <+> h | h <- hs ]

-- | The product of two subgroups of G
product :: Group a => [a] -> [a] -> [a]
product as bs = [ a <+> b | a <- as , b <- bs ]

-- | Quotient groups, G/H, assumes that H is normal
--   This version does not respect possible duplicates
quotient :: Group a => [a] -> [a] -> [[a]]
quotient gs hs = [ leftCoset g hs | g <- gs ]

-- This version remove duplicates, for example:
-- > quotient z4 subZ4 
-- [[Z4 0,Z4 2],[Z4 1,Z4 3],[Z4 2,Z4 0],[Z4 3,Z4 1]]
-- > quotientGroups z4 subZ4 
-- [[Z4 0,Z4 2],[Z4 1,Z4 3]]
quotientGroups :: (Ord a, Group a) => [a] -> [a] -> [[a]]
quotientGroups gs hs = nub [ sort (leftCoset g hs) | g <- gs ]

(//) :: (Ord a, Group a) => [a] -> [a] -> [[a]]
(//) = quotientGroups
