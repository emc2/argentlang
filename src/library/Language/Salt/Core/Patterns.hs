-- Copyright (c) 2015 Eric McCorkle.  All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions
-- are met:
--
-- 1. Redistributions of source code must retain the above copyright
--    notice, this list of conditions and the following disclaimer.
--
-- 2. Redistributions in binary form must reproduce the above copyright
--    notice, this list of conditions and the following disclaimer in the
--    documentation and/or other materials provided with the distribution.
--
-- 3. Neither the name of the author nor the names of any contributors
--    may be used to endorse or promote products derived from this software
--    without specific prior written permission.
--
-- THIS SOFTWARE IS PROVIDED BY THE AUTHORS AND CONTRIBUTORS ``AS IS''
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
-- TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
-- PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHORS
-- OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
-- SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
-- LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF
-- USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
-- ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
-- OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT
-- OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
-- SUCH DAMAGE.
{-# OPTIONS_GHC -funbox-strict-fields -Wall -Werror #-}

-- | Pattern matching implementation.  This module contains a single
-- function which implements the pattern matching functionality.
--
-- The single function in this module attempts to create a unifier
-- from a pattern and a term.
module Language.Salt.Core.Patterns(
       patternMatch,
       patternTypes
       ) where

import Data.Default
import Language.Salt.Core.Syntax

import qualified Data.Map as Map

-- | Given sorted lists of bindings and terms, attempt to match them up
-- and produce a unifier
zipBinds :: (Default sym, Eq sym, Ord sym) =>
            Bool -> [(sym, Pattern sym (Term sym) sym)] ->
            [(sym, Term sym sym)] -> [(sym, Term sym sym)] ->
            Maybe [(sym, Term sym sym)]
zipBinds strict allbinds @ ((name, bind) : binds) ((name', term) : terms) result
-- If the names match, then run pattern match
  | name == name' =
    do
      result' <- patternMatchTail result bind term
      zipBinds strict binds terms result'
-- If the names don't match, and we're not strict, discard the term
-- and keep going
  | not strict = zipBinds strict allbinds terms result
-- Otherwise, we have an error
  | otherwise = Nothing
-- Termination condition: run out of both lists, regardless of strictness
zipBinds _ [] [] result = return result
-- Termination condition: run out of binders, and we're not strict
zipBinds False [] _ result = return result
-- Everything else is a match error
zipBinds _ _ _ _ = Nothing

-- | Tail-recursive work function for pattern matching
patternMatchTail :: (Default sym, Eq sym, Ord sym) =>
                    [(sym, (Term sym sym))] ->
                    Pattern sym (Term sym) sym ->
                    Term sym sym ->
                    Maybe [(sym, (Term sym sym))]
patternMatchTail result Deconstruct { deconstructConstructor = constructor,
                                      deconstructStrict = strict,
                                      deconstructBinds = binds } term
  | constructor == defaultVal =
    case term of
      Record { recVals = vals } ->
        zipBinds strict (Map.toAscList binds) (Map.toAscList vals) result
      _ -> Nothing
  | otherwise =
    case term of
      Call { callFunc = Var { varSym = func }, callArgs = args } ->
        if func == constructor
        then zipBinds strict (Map.toAscList binds) (Map.toAscList args) result
        else Nothing
      _ -> Nothing
-- As bindings bind the current term and then continue
patternMatchTail result As { asName = name, asBind = bind } t =
  patternMatchTail ((name, t) : result) bind t
-- Names grab anything
patternMatchTail result Name { nameSym = sym } t =
  return ((sym, t) : result)
-- Constants must be equal
patternMatchTail result (Constant t1) t2
  | t1 == t2 = return result
  | otherwise = Nothing

-- | Take a pattern and a term and attempt to match the pattern
-- represented by the binding.  If the match succeeds, return a
-- unifier in the form of a map from bound variables to terms.  If the
-- match fails, return nothing.
patternMatch :: (Default sym, Eq sym, Ord sym) =>
                Pattern sym (Term sym) sym
             -- ^ The pattern being matched.
             -> Term sym sym
             -- ^ The term attempting to match the pattern.
             -> Maybe [(sym, (Term sym sym))]
             -- ^ A list of bindings from the pattern, or Nothing.
patternMatch = patternMatchTail []

-- | Given sorted lists of bindings and types, get a list of variable,
-- type pairs that get bound.
zipTypes :: (Default sym, Eq sym, Ord sym) =>
            Bool -> [(sym, Pattern sym (Term sym) sym)] ->
            [(sym, Term sym sym)] -> [(sym, Term sym sym)] ->
            Maybe [(sym, Term sym sym)]
zipTypes strict allbinds @ ((name, bind) : binds) ((name', term) : terms) result
-- If the names match, then run pattern match
  | name == name' =
    do
      result' <- patternTypesTail result bind term
      zipBinds strict binds terms result'
-- If the names don't match, and we're not strict, discard the term
-- and keep going
  | not strict = zipBinds strict allbinds terms result
-- Otherwise, we have an error
  | otherwise = Nothing
-- Termination condition: run out of both lists, regardless of strictness
zipTypes _ [] [] result = return result
-- Termination condition: run out of binders, and we're not strict
zipTypes False [] _ result = return result
-- Everything else is a match error
zipTypes _ _ _ _ = Nothing

patternTypesTail result Deconstruct { deconstructConstructor = constructor,
                                      deconstructStrict = strict,
                                      deconstructBinds = binds } term
  | constructor == defaultVal =
    case term of
      Record { recVals = vals } ->
        zipTypes strict (Map.toAscList binds) (Map.toAscList vals) result
      _ -> Nothing
  | otherwise =
    case term of
      Call { callFunc = Var { varSym = func }, callArgs = args } ->
        if func == constructor
        then zipTypes strict (Map.toAscList binds) (Map.toAscList args) result
        else Nothing
      _ -> Nothing
-- As bindings bind the current term and then continue
patternTypesTail result As { asName = name, asBind = bind } t =
  patternTypesTail ((name, t) : result) bind t
-- Name patterns bind the type to the pattern
patternTypesTail result Name { nameSym = sym } t = Just [(sym, t)]
-- Constants don't bind any symbols
patternTypesTail result (Constant _) t2 = Just []

-- | Take a pattern and a type and extract the typings for all the
-- variables bound by this pattern.  Note: this is only guaranteed to
-- work for well-typed patterns; if the pattern does not have the
-- given type, it may fail.
patternTypes :: (Default sym, Eq sym, Ord sym) =>
                Pattern sym (Term sym) sym
             -- ^ The pattern being matched.
             -> Term sym sym
             -- ^ The type given to the pattern.
             -> Maybe [(sym, Term sym sym)]
             -- ^ A list of bindings from the pattern, or Nothing.
patternMatch = patternTypesTail []
