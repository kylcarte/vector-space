-- WARNING: this module depends on type families working fairly well, and
-- requires ghc version at least 6.9.  I didn't find a way to specify that
-- dependency in the .cabal.
-- 
{-# LANGUAGE TypeOperators, TypeFamilies, UndecidableInstances
  , FlexibleInstances, MultiParamTypeClasses
  #-}
{-# OPTIONS_GHC -Wall -fno-warn-orphans #-}
----------------------------------------------------------------------
-- |
-- Module      :  Data.Basis
-- Copyright   :  (c) Conal Elliott 2008
-- License     :  BSD3
-- 
-- Maintainer  :  conal@conal.net
-- Stability   :  experimental
-- 
-- Basis of a vector space, as an associated type.
--  This version works with @Data.VectorSpace@, thus avoiding a bug in
--  ghc-6.9..
----------------------------------------------------------------------

module Data.Basis (HasBasis(..), linearCombo, recompose) where

import Control.Arrow (first)
import Data.Either

import Data.VectorSpace

class VectorSpace v s => HasBasis v s where
  -- | Representation of the canonical basis for @v@
  type Basis v :: *
  -- | Interpret basis rep as a vector
  basisValue   :: Basis v -> v
  -- | Extract coordinates
  decompose    :: v -> [(Basis v, s)]
  -- | Experimental version.  More elegant definitions, and friendly to
  -- infinite-dimensional vector spaces.
  decompose'   :: v -> (Basis v -> s)

-- TODO: Switch from fundep to associated type.  Eliminate the second type
-- parameter in VectorSpace and HasBasis.
-- Blocking bug: http://hackage.haskell.org/trac/ghc/ticket/2448
-- Fixed in ghc 6.10.

-- Defining property: recompose . decompose == id

-- | Linear combination
linearCombo :: VectorSpace v s => [(v,s)] -> v
linearCombo ps = sumV [s *^ v | (v,s) <- ps]

-- | Turn a basis decomposition back into a vector.
recompose :: HasBasis v s => [(Basis v, s)] -> v
recompose = linearCombo . fmap (first basisValue)

-- recompose ps = linearCombo (first basisValue <$> ps)


-- recompose = sumV . fmap (\ (b,s) -> s *^ basisValue b)

instance HasBasis Float Float where
  type Basis Float = ()
  basisValue ()    = 1
  decompose s      = [((),s)]
  decompose' s     = const s

instance HasBasis Double Double where
  type Basis Double = ()
  basisValue ()     = 1
  decompose s       = [((),s)]
  decompose' s     = const s

instance (HasBasis u s, HasBasis v s) => HasBasis (u,v) s where
  type Basis (u,v)     = Basis u `Either` Basis v
  basisValue (Left  a) = (basisValue a, zeroV)
  basisValue (Right b) = (zeroV, basisValue b)
  decompose  (u,v)     = decomp2 Left u ++ decomp2 Right v
  decompose' (u,v)     = decompose' u `either` decompose' v

decomp2 :: HasBasis w s => (Basis w -> b) -> w -> [(b, s)]
decomp2 inject = fmap (first inject) . decompose

instance (HasBasis u s, HasBasis v s, HasBasis w s) => HasBasis (u,v,w) s where
  type Basis (u,v,w) = Basis (u,(v,w))
  basisValue         = unnest3 . basisValue
  decompose          = decompose . nest3
  decompose'         = decompose' . nest3

unnest3 :: (a,(b,c)) -> (a,b,c)
unnest3 (a,(b,c)) = (a,b,c)

nest3 :: (a,b,c) -> (a,(b,c))
nest3 (a,b,c) = (a,(b,c))

-- Without UndecidableInstances:
-- 
--     Application is no smaller than the instance head
--       in the type family application: Basis (u, (v, w))
--     (Use -fallow-undecidable-instances to permit this)
--     In the type synonym instance declaration for `Basis'
--     In the instance declaration for `HasBasis (u, v, w)'
-- 
-- A work-around:
-- 
--     type Basis (u,v,w) = Basis u `Either` Basis (v,w)


instance (Eq a, HasBasis u s) => HasBasis (a -> u) s where
  type Basis (a -> u) = (a, Basis u)
  basisValue (a,b) = f
    where f a' | a == a'   = bv
               | otherwise = zeroV
          bv = basisValue b
  decompose = error "decompose: not defined on functions"
  decompose' g (a,b) = decompose' (g a) b

{-

---- Testing

t1 = basisValue () :: Float
t2 = basisValue () :: Double
t3 = basisValue (Right ()) :: (Float,Double)
t4 = basisValue (Right (Left ())) :: (Float,Double,Float)

-}

