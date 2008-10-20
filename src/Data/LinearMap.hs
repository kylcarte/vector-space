{-# LANGUAGE TypeOperators, FlexibleContexts #-}
{-# OPTIONS_GHC -Wall -fno-warn-orphans #-}
-- {-# OPTIONS_GHC -fglasgow-exts -funbox-strict-fields #-}
-- {-# OPTIONS_GHC -ddump-simpl-stats -ddump-simpl #-}
----------------------------------------------------------------------
-- |
-- Module      :  Data.LinearMap
-- Copyright   :  (c) Conal Elliott 2008
-- License     :  BSD3
-- 
-- Maintainer  :  conal@conal.net
-- Stability   :  experimental
-- 
-- Linear maps
----------------------------------------------------------------------

module Data.LinearMap
  ( (:-*) , linear, lapply
  ) where

import Control.Arrow (first)
import Data.Function

import Data.VectorSpace
import Data.MemoTrie
import Data.Basis

-- | Linear map, represented a as a memo function from basis to values.
type u :-* v = Basis u :->: v

-- | Function (assumed linear) as linear map.
linear :: (VectorSpace u s, VectorSpace v s', HasBasis u s, HasTrie (Basis u)) =>
          (u -> v) -> (u :-* v)
linear f = trie (f . basisValue)

-- | Apply a linear map to a vector.
lapply :: (VectorSpace u s, VectorSpace v s, HasBasis u s, HasTrie (Basis u)) =>
          (u :-* v) -> (u -> v)
lapply lm = linearCombo . fmap (first (untrie lm)) . decompose


-- TODO: unfst, unsnd, pair, unpair

