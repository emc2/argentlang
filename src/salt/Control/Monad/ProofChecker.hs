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

-- | A module containing a monad transformer implementation that
-- encapsulates all proof checking state.
module Control.Monad.ProofChecker(
       ProofCheckerT
       ) where

import Control.Monad.State(StateT(..), runStateT, get, put)
import Control.Monad.ProofErrors.Class
import Control.Monad.ProofNames.Class
import Data.Default
import Data.Map
import Data.Pos
import Language.Salt.Core.Proofs.ProofState
import Language.Salt.Core.Syntax
import Prelude hiding (lookup)

newtype ProofCheckerT sym m a = ProofCheckerT ((StateT (ProofState sym) m) a)

unpackProofCheckerT :: ProofCheckerT sym m a -> (StateT (ProofState sym) m) a
unpackProofCheckerT (ProofCheckerT w) = w

-- | Execute a proof recorder monad, and return the result along with
-- the recorded proof.
runProofCheckerT :: MonadProofErrors sym m =>
                    ProofCheckerT sym m a
                 -- ^ The monad to execute.
                 -> ProofState sym
                 -- ^ The initial proof state
                 -> m a
                 -- ^ The result.
runProofCheckerT (ProofCheckerT m) proofstate =
  do
    (out, state) <- runStateT m proofstate
    case state of
      -- If all goals are complete, we're good
      ProofState { proofGoals = [] } -> return out
      -- Otherwise, log an error and then return the result
      _ ->
        do
          incomplete
          return out

apply' :: (Ord sym, Default sym, MonadProofErrors sym m) =>
          Pos -> sym -> (StateT (ProofState sym) m) ()
apply' p name =
  do
    state <- get
    case state of
      -- Operate on the first goal.
      ProofState { proofGoals = Goal { goalProp = prop,
                                       goalTruthCtx = ctx } : rest } ->
        case lookup name ctx of
          -- If we get a proposition out of the context, compare it to
          -- the current one.
          Just prop' ->
            if prop' == prop
               -- If the propositions are the same, this closes the
               -- current branch.
               then put (state { proofGoals = rest })
               -- Otherwise, log an error
               else exactMismatch p name prop' prop
          -- If the proposition is undefined, log an error.
          Nothing -> undefProp p name
      -- If the proof is already complete, log an error.
      ProofState { proofGoals = [] } -> complete

intro' :: (Ord sym, Default sym, MonadProofErrors sym m,
           MonadProofNames sym m) =>
          Pos -> sym -> (StateT (ProofState sym) m) ()
intro' p name =
  do
    state <- get
    case state of
      -- Operate on the first goal
      ProofState { proofGoals =
                      goal @ Goal { goalProp = prop,
                                    goalTruthCtx = ctx } : rest } ->
        do
          implies <- impliesProp
          premise <- premiseName
          consequence <- consequenceName
          case prop of
            -- If it's a call, then it's possibly an implication.
            Call { callFunc = func, callArgs = args } ->
              -- Make sure the function is the implies proposition.
              if func == implies && 2 == size ctx
                -- Get the arguments.
                then case (lookup premise args, lookup consequence args) of
                  --
                  (Just premiseProp, Just consequenceProp) ->
                    put (state { proofGoals =
                                   goal { goalProp = consequenceProp,
                                          goalTruthCtx =
                                            insert name premiseProp ctx } :
                                   rest })
                  _ -> introMismatch p prop
                --
                else introMismatch p prop
            -- Otherwise log an introMismatch
            _ -> introMismatch p prop
      -- If the proof is already complete, log an error.
      ProofState { proofGoals = [] } -> complete
{-
introVars' :: (MonadProofErrors m, MonadProofNames sym m) =>
              Pos -> (StateT (ProofState sym) m) ()
introVars' p =
-}
cut' :: (Ord sym, Default sym, MonadProofErrors sym m,
         MonadProofNames sym m) =>
        Pos -> Term sym sym -> (StateT (ProofState sym) m) ()
cut' p cutprop =
  do
    state <- get
    case state of
      -- Operate on the first goal
      ProofState { proofGoals = goal @ Goal { goalProp = prop } : rest } ->
        do
          implies <- impliesProp
          premise <- premiseName
          consequence <- consequenceName
          put (state { proofGoals =
                         goal { goalProp = cutprop } :
                         goal { goalProp =
                                  Call { callFunc = implies,
                                         callArgs =
                                           fromList [ (premise, cutprop),
                                                      (consequence, prop) ],
                                         callPos = p } } :
                         rest })
      -- If the proof is already complete, log an error.
      ProofState { proofGoals = [] } -> complete
{-
apply' :: MonadProofErrors m => Pos -> Term sym sym -> Term sym sym ->
          (StateT (ProofState sym) m) ()
apply' p prop arg = tell [Apply { applyProp = prop, applyArg = arg,
                                  applyPos = p }]
-}
